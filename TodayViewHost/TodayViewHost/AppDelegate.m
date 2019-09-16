//
//  AppDelegate.m
//  TodayViewHost
//
//  Created by https://github.com/jslegendre on 8/26/19.
//  Copyright © 2019 Jeremy Legendre. All rights reserved.
//

#import "AppDelegate.h"
#import <NotificationCenter/NotificationCenter.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface AppDelegate ()
@property void *ncFrameworkHandle;
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *widgetTable;
@property (weak) IBOutlet NSButton *openButton;
@property (weak) IBOutlet NSButton *closeButton;
@property (strong) NSMutableArray<NCWidget*> *widgets;
@end

@implementation AppDelegate

- (IBAction)openWidget:(id)sender {
    NSInteger row = [self.widgetTable selectedRow];
    [[self.widgets objectAtIndex:row] run];
    
    [self.closeButton setEnabled:YES];
    [self.openButton setEnabled:NO];
}

- (IBAction)stopWidget:(id)sender {
    NSInteger row = [self.widgetTable selectedRow];
    [[self.widgets objectAtIndex:row] stop];
    
    [self.closeButton setEnabled:NO];
    [self.openButton setEnabled:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    /*
     All app extensions have an attribute in the info.plist called NSExtensionPointIdentifier
     which describes what "type" of plugin it is.
     The NSExtensionPointName key here must match the value for the extensions NSExtensionPointIdentifier.
     The NSExtension class can all app extensions that contain the NSExtensionPointIdentifier we want.
     com.apple.widget-extension is what the Notification Center uses for 'Today View' extensions.
     
     The result of +[NSExtension extensionsWithMatchingAttributes:error:] is an array of instantiated
     NSExtension objects; one for each app extension found.
     */

    NSDictionary *d = @{@"NSExtensionPointName" : @"com.apple.widget-extension"};
    NSArray * ncWidgets = objc_msgSend(objc_getClass("NSExtension"), sel_getUid("extensionsWithMatchingAttributes:error:"), d, nil);
    
    self.widgets = [NSMutableArray new];
    
    [self.closeButton setEnabled:NO];
    [self.openButton setEnabled:NO];
    
    for(id extension in ncWidgets) {
        NCWidget *widget = [[NCWidget alloc] initWithExtension:extension];
        [self.widgets addObject:widget];
    }
    
    [self.widgetTable reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.widgets.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [[self.widgets objectAtIndex:row] name];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *tableView = notification.object;
    NCWidget *selectedWidget = [self.widgets objectAtIndex:tableView.selectedRow];
    if([selectedWidget isRunning]) {
        [self.closeButton setEnabled:YES];
        [self.openButton setEnabled:NO];
    } else {
        [self.closeButton setEnabled:NO];
        [self.openButton setEnabled:YES];
    }
    
}

@end
