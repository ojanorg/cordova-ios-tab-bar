/*
 *  CDVTabBar
 *
 *  Based on:
 *  NativeControls
 *
 *  Updated by Web2Life AB
 *  MIT Licensed
 *
 *  Originally this code was developed my Michael Nachbaur
 *  And Jesse MacFadyen on 10-02-03.
 *  Formerly -> PhoneGap :: UIControls.m
 *  Created by Michael Nachbaur on 13/04/09.
 *  Copyright 2009 Decaf Ninja Software. All rights reserved.
 */
#import "CDVTabBar.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@implementation CDVTabBar
#ifndef __IPHONE_3_0
@synthesize webView;
#endif

@synthesize callbackId = _callbackId;
@synthesize listenerCallbackId = _listenerCallbackId;

- (void)pluginInitialize
{
    tabBarItems = [[NSMutableDictionary alloc] initWithCapacity:5];
    originalWebViewBounds = self.webView.bounds;
}

#pragma mark - Listener
/**
 * Bind listener for didSelectItem.
 */
-(void)bindListener:(CDVInvokedUrlCommand*)command
{
    self.listenerCallbackId = command.callbackId;

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [pluginResult setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark - TabBar

/**
 * Create a native tab bar at either the top or the bottom of the display.
 * @brief creates a tab bar
 * @param arguments unused
 * @param options unused
 */
- (void)createTabBar:(CDVInvokedUrlCommand*)command
{
	tabBar = [UITabBar new];
	tabBar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	[tabBar sizeToFit];
	tabBar.delegate = self;

    if ( SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        tabBar.barStyle = UIBarStyleBlack;
        tabBar.translucent = NO;
        tabBar.barTintColor = [UIColor colorWithRed:0.122 green:0.122 blue:0.122 alpha:1]; /*#1f1f1f*/
        tabBar.tintColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1]; /*#ffffff*/
    } else {
        // Pre iOS 7
        tabBar.opaque = YES;
    }
	tabBar.multipleTouchEnabled   = NO;
	tabBar.autoresizesSubviews    = YES;
	tabBar.hidden                 = YES;
	tabBar.userInteractionEnabled = YES;

    self.webView.superview.autoresizesSubviews = YES;

	/* Styling hints REF UIInterface.h

	 tabBar.alpha = 0.5;
	 tabBar.tintColor = [UIColor colorWithRed:1.000 green:0.000 blue:0.000 alpha:1.000];

	 */

	[self.webView.superview addSubview:tabBar];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

/**
 * Show the tab bar after its been created.
 * @brief show the tab bar
 * @param arguments unused
 * @param options used to indicate options for where and how the tab bar should be placed
 * - \c height integer indicating the height of the tab bar (default: \c 49)
 * - \c position specifies whether the tab bar will be placed at the \c top or \c bottom of the screen (default: \c bottom)
 */
- (void)showTabBar:(CDVInvokedUrlCommand*)command
{

    NSDictionary *options = [command.arguments objectAtIndex:0];

    if (!tabBar) {
        [self createTabBar:nil];
    }

	// if we are calling this again when its shown, reset
	if (!tabBar.hidden) {
		return;
	}

    CGFloat height = 0.0f;
    BOOL atBottom = YES;

    //	CGRect offsetRect = [ [UIApplication sharedApplication] statusBarFrame];

    if (options)
	{
        height   = [[options objectForKey:@"height"] floatValue];
        atBottom = [[options objectForKey:@"position"] isEqualToString:@"bottom"];
    }
	if(height == 0)
	{
		height = 49.0f;
		atBottom = YES;
	}

    tabBar.hidden = NO;
    CGRect webViewBounds = originalWebViewBounds;
    CGRect tabBarBounds;

	NSNotification* notif = [NSNotification notificationWithName:@"CDVLayoutSubviewAdded" object:tabBar];
	[[NSNotificationQueue defaultQueue] enqueueNotification:notif postingStyle: NSPostASAP];

    if (atBottom) {
        tabBarBounds = CGRectMake(
                                  webViewBounds.origin.x,
                                  webViewBounds.origin.y + webViewBounds.size.height - height,
                                  webViewBounds.size.width,
                                  height
                                  );
        webViewBounds = CGRectMake(
                                   webViewBounds.origin.x,
                                   webViewBounds.origin.y,
                                   webViewBounds.size.width,
                                   webViewBounds.size.height - height
                                   );
    } else {
        tabBarBounds = CGRectMake(
                                  webViewBounds.origin.x,
                                  webViewBounds.origin.y,
                                  webViewBounds.size.width,
                                  height
                                  );
        webViewBounds = CGRectMake(
                                   webViewBounds.origin.x,
                                   webViewBounds.origin.y + height,
                                   webViewBounds.size.width,
                                   webViewBounds.size.height - height
                                   );
    }

    [tabBar setFrame:tabBarBounds];


    [self.webView setFrame:webViewBounds];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

/**
 * Hide the tab bar
 * @brief hide the tab bar
 * @param arguments unused
 * @param options unused
 */
- (void)hideTabBar:(CDVInvokedUrlCommand*)command
{
    if (!tabBar) {
        [self createTabBar:nil];
    }
	tabBar.hidden = YES;

	NSNotification* notif = [NSNotification notificationWithName:@"CDVLayoutSubviewRemoved" object:tabBar];
	[[NSNotificationQueue defaultQueue] enqueueNotification:notif postingStyle: NSPostASAP];

	[self.webView setFrame:originalWebViewBounds];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

/**
 * Create a new tab bar item for use on a previously created tab bar.  Use ::showTabBarItems to show the new item on the tab bar.
 *
 * If the supplied image name is one of the labels listed below, then this method will construct a tab button
 * using the standard system buttons.  Note that if you use one of the system images, that the \c title you supply will be ignored.
 * - <b>Tab Buttons</b>
 *   - tabButton:More
 *   - tabButton:Favorites
 *   - tabButton:Featured
 *   - tabButton:TopRated
 *   - tabButton:Recents
 *   - tabButton:Contacts
 *   - tabButton:History
 *   - tabButton:Bookmarks
 *   - tabButton:Search
 *   - tabButton:Downloads
 *   - tabButton:MostRecent
 *   - tabButton:MostViewed
 * @brief create a tab bar item
 * @param arguments Parameters used to create the tab bar
 *  -# \c name internal name to refer to this tab by
 *  -# \c title title text to show on the tab, or null if no text should be shown
 *  -# \c image image filename or internal identifier to show, or null if now image should be shown
 *  -# \c tag unique number to be used as an internal reference to this button
 * @param options Options for customizing the individual tab item
 *  - \c badge value to display in the optional circular badge on the item; if nil or unspecified, the badge will be hidden
 */
- (void)createTabBarItem:(CDVInvokedUrlCommand*)command
{
    NSArray *arguments = command.arguments;
    NSDictionary *options = [arguments objectAtIndex:4];

    if (!tabBar) {
        [self createTabBar:nil];
    }

    NSString  *name      = [arguments objectAtIndex:0];
    NSString  *title     = [arguments objectAtIndex:1];
    NSString  *imageName = [arguments objectAtIndex:2];
    int tag              = [[arguments objectAtIndex:3] intValue];

    if (![imageName isKindOfClass:[NSString class]]) {
        imageName = nil;
    }

    UITabBarItem *item;
    if ([imageName length] > 0) {
        UITabBarSystemItem systemItem;
        BOOL buttonIsSystemImage = NO;
        if ([imageName isEqualToString:@"tabButton:More"]) {
            systemItem = UITabBarSystemItemMore;
            buttonIsSystemImage = YES;
        }
        if ([imageName isEqualToString:@"tabButton:Favorites"]) {
            systemItem = UITabBarSystemItemFavorites;
            buttonIsSystemImage = YES;
        }
        if ([imageName isEqualToString:@"tabButton:Featured"]) {
            systemItem = UITabBarSystemItemFeatured;
            buttonIsSystemImage = YES;
        }
        if ([imageName isEqualToString:@"tabButton:TopRated"]) {
            systemItem = UITabBarSystemItemTopRated;
            buttonIsSystemImage = YES;
        }
        if ([imageName isEqualToString:@"tabButton:Recents"]) {
            systemItem = UITabBarSystemItemRecents;
            buttonIsSystemImage = YES;
        }
        if ([imageName isEqualToString:@"tabButton:Contacts"]) {
            systemItem = UITabBarSystemItemContacts;
            buttonIsSystemImage = YES;
        }
        if ([imageName isEqualToString:@"tabButton:History"]) {
            systemItem = UITabBarSystemItemHistory;
            buttonIsSystemImage = YES;
        }
        if ([imageName isEqualToString:@"tabButton:Bookmarks"]) {
            systemItem = UITabBarSystemItemBookmarks;
            buttonIsSystemImage = YES;
        }
        if ([imageName isEqualToString:@"tabButton:Search"]) {
            systemItem = UITabBarSystemItemSearch;
            buttonIsSystemImage = YES;
        }
        if ([imageName isEqualToString:@"tabButton:Downloads"]) {
            systemItem = UITabBarSystemItemDownloads;
            buttonIsSystemImage = YES;
        }
        if ([imageName isEqualToString:@"tabButton:MostRecent"]) {
            systemItem = UITabBarSystemItemMostRecent;
            buttonIsSystemImage = YES;
        }
        if ([imageName isEqualToString:@"tabButton:MostViewed"]) {
            systemItem = UITabBarSystemItemMostViewed;
            buttonIsSystemImage = YES;
        }
        if (buttonIsSystemImage)
            item = [[UITabBarItem alloc] initWithTabBarSystemItem:systemItem tag:tag];
    }

    if (!item) {
        UIImage *image;
        if (imageName) {
            image = [UIImage imageNamed:imageName];
        }
        item = [[UITabBarItem alloc] initWithTitle:title image:image tag:tag];
    }

    // Set badge if needed
    if (![options isKindOfClass:[NSNull class]]) {
        if ([options objectForKey:@"badge"]) {
            item.badgeValue = [options objectForKey:@"badge"];
        }
    }

    [tabBarItems setObject:item forKey:name];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


/**
 * Update an existing tab bar item to change its badge value.
 * @brief update the badge value on an existing tab bar item
 * @param arguments Parameters used to identify the tab bar item to update
 *  -# \c name internal name used to represent this item when it was created
 * @param options Options for customizing the individual tab item
 *  - \c badge value to display in the optional circular badge on the item; if nil or unspecified, the badge will be hidden
 */
- (void)updateTabBarItem:(CDVInvokedUrlCommand*)command
{

    NSArray *arguments = command.arguments;
    NSDictionary *options = [arguments objectAtIndex:1];

    if (!tabBar) {
        [self createTabBar:nil];
    }

    NSString  *name = [arguments objectAtIndex:0];
    UITabBarItem *item = [tabBarItems objectForKey:name];
    if (item) {
        item.badgeValue = [options objectForKey:@"badge"];
    }

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


/**
 * Show previously created items on the tab bar
 * @brief show a list of tab bar items
 * @param arguments the item names to be shown
 * @param options dictionary of options, notable options including:
 *  - \c animate indicates that the items should animate onto the tab bar
 * @see createTabBarItem
 * @see createTabBar
 */
- (void)showTabBarItems:(CDVInvokedUrlCommand*)command
{

    NSArray *arguments = command.arguments;
    int count = [arguments count];
    //NSDictionary *options = [arguments objectAtIndex:];

    if (!tabBar) {
        [self createTabBar:nil];
    }

    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:count];
    for (int i = 0; i < count; i++) {
        NSString *itemName = [arguments objectAtIndex:i];
        UITabBarItem *item = [tabBarItems objectForKey:itemName];
        if (item) {
            [items addObject:item];
        }
    }

    BOOL animateItems = NO;
    /*
     if ([options objectForKey:@"animate"])
     animateItems = [(NSString*)[options objectForKey:@"animate"] boolValue];
     */
    [tabBar setItems:items animated:animateItems];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

/**
 * Manually select an individual tab bar item, or nil for deselecting a currently selected tab bar item.
 * @brief manually select a tab bar item
 * @param arguments the name of the tab bar item to select
 * @see createTabBarItem
 * @see showTabBarItems
 */
- (void)selectTabBarItem:(CDVInvokedUrlCommand*)command
{
    NSArray *arguments = command.arguments;

    if (!tabBar) {
        [self createTabBar:nil];
    }

    NSString *itemName = [arguments objectAtIndex:0];
    UITabBarItem *item = [tabBarItems objectForKey:itemName];
    if (item) {
        tabBar.selectedItem = item;
    } else {
        tabBar.selectedItem = nil;
    }

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
	// Create Plugin Result
	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:item.tag];
    [pluginResult setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.listenerCallbackId];
}

@end
