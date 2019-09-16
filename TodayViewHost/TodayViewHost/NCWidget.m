//
//  NCWidget.m
//  TodayViewHost
//
//  Created by https://github.com/jslegendre on 9/11/19.
//  Copyright © 2019 Jeremy Legendre. All rights reserved.
//

@import QuartzCore.CATransaction;

#import "NCWidget.h"
#import "NSRemoteView.h"
#import <objc/runtime.h>
#import <objc/message.h>

extern int NCViewLayoutSubview(NSView*, NSRemoteView*);

@interface NCWidgetWindowHeader : NSView
@property (strong) NSView *titleView;
@property (strong) NSView *editButtonView;
@property (strong) NSTextField *titleField;
@property (strong) NSImageView *iconImageView;
@property (strong) NSButton *editButton;
@end

@implementation NCWidgetWindowHeader

-(instancetype)initWithWindow:(NSWindow*)window {
    if (!(self = [super initWithFrame:CGRectMake(0, 0, window.contentView.frame.size.width, 20)]))
        return nil;
    
    NSView *themeFrame = [[window contentView] superview];
    NSRect c = [themeFrame frame];
    
    self.titleView = [[NSView alloc] initWithFrame:CGRectMake(0, 0, 180, 20)];
    self.titleField = [[NSTextField alloc] initWithFrame:CGRectMake(23, -3, 160, 20)];
    self.titleField.bezeled = NO;
    self.titleField.editable = NO;
    self.titleField.drawsBackground = NO;
    
    self.iconImageView = [[NSImageView alloc] initWithFrame:CGRectMake(3, 0, 18, 18)];
    [self.titleView addSubview:self.iconImageView];
    [self.titleView addSubview:self.titleField];
    
    self.editButtonView = [[NSView alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    self.editButton = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    [self.editButton setImage:[NSImage imageNamed:NSImageNameTouchBarGetInfoTemplate]];
    [self.editButton setImageScaling:NSImageScaleProportionallyUpOrDown];
    [self.editButton setBordered:NO];
    [self.editButtonView addSubview:self.editButton];
    
    NSRect r = [self.editButtonView frame];
    NSRect newFrame = NSMakeRect(
                                 (self.frame.size.width - r.size.width) - 5,
                                 (self.frame.size.height - r.size.height),
                                 r.size.width,
                                 r.size.height);
    
    [self.editButtonView setFrame:newFrame];
    [self.editButton setFrame:CGRectMake((self.editButtonView.frame.size.width - self.editButton.frame.size.width) + 2,
                                         (self.editButtonView.frame.size.height - self.editButton.frame.size.height),
                                         self.editButton.frame.size.width,
                                         self.editButton.frame.size.height)];
    
    r = [self.titleView frame];
    newFrame = NSMakeRect(5,
                          self.frame.size.height - r.size.height,
                          r.size.width,
                          r.size.height);
    
    [self.titleView setFrame:newFrame];
    
    [self setFrame:CGRectMake(0, window.frame.size.height, c.size.width, c.size.height)];
    [self addSubview:self.titleView];
    [self addSubview:self.editButtonView];
    
    NSVisualEffectView *effectView = [[NSVisualEffectView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height)];
    effectView.material = NSVisualEffectMaterialPopover;
    effectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    effectView.state = NSVisualEffectStateActive;
    [self addSubview:effectView positioned:NSWindowBelow relativeTo:nil];
    effectView.autoresizingMask = NSViewHeightSizable;

    return self;
}

- (BOOL)isFlipped {
    return YES;
}

@end

@interface NCWidgetWindow : NSWindow
@property (strong) NCWidgetWindowHeader *header;
@property (assign) NSView *widgetContent;
@end

@implementation NCWidgetWindow

- (instancetype)initWithWidgetHostViewController:(__kindof NSViewController *)viewController {
    if (!(self = [super initWithContentRect:NSRectFromString(@"{{700, 500}, {320, 50}}") styleMask:NSWindowStyleMaskTexturedBackground|NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO])) return nil;
    
    self.widgetContent = viewController.view;
    self.header = [[NCWidgetWindowHeader alloc] initWithWindow:self];

    NSTitlebarAccessoryViewController* vc = [[NSTitlebarAccessoryViewController alloc] init];
    vc.view = self.header;
    vc.layoutAttribute = NSLayoutAttributeRight;
    [self addTitlebarAccessoryViewController:vc];
    [self.contentView addSubview:viewController.view];
    
    NSVisualEffectView *effectView = [[NSVisualEffectView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height)];
    effectView.material = NSVisualEffectMaterialPopover;
    effectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    effectView.state = NSVisualEffectStateActive;
    [self.contentView addSubview:effectView positioned:NSWindowBelow relativeTo:nil];
    effectView.autoresizingMask = NSViewHeightSizable;
    
    return self;
}

- (BOOL)isMovableByWindowBackground {
    return NO;
}

- (BOOL)hasShadow {
    return NO;
}

- (NSString*)title {
    return self.header.titleField.stringValue;
}

- (void)setTitle:(NSString *)title {
    self.header.titleField.stringValue = title;
}

- (NSImage*)icon {
    return self.header.iconImageView.image;
}

- (void)setIcon:(NSImage*)icon {
    self.header.iconImageView.image = icon;
}

- (void)setEditButtonAction:(SEL)editButtonAction {
    self.header.editButton.action = editButtonAction;
}

- (void)setEditButtonTarget:(id)target {
    self.header.editButton.target = target;
}

@end

@interface NCWidget ()
@property (retain) id extension;
@property (strong) __kindof NSView *remoteView;
@end

@implementation NCWidget

- (void)toggleWidgetMode {
    id proxyObject = objc_msgSend(self.remotePlugIn, sel_getUid("proxyObject"));
    objc_msgSend(proxyObject, sel_getUid("widgetServiceSetEditMode:"),
                 self.widgetMode == 0 ? 1 : 0 );
}

-(instancetype)initWithExtension:(id)extension {
    if (!(self = [super init])) return nil;
    self.isRunning = NO;
    self.extension = extension;
    /*
     NCRemotePlugIn : NSExtensionContext <NSCopying>.
     -[NCRemotePlugIn initWithExtension:] initializes an empty NSExtensionContext ([super init]), assigns
     the extension passed to the ivar 'extension', then calls [self setupPlugIn] which grabs and stores
     information about the app extension such as its' path, bundle id, icon image, NSExtensionPointVersion,
     etc. Once that has finished it will call [self _commonSetup] which registers an NSNotificationCenter
     observer for NCRemotePlugInExtensionInvalidatedNotification.
    */
    Class NCRemotePlugInClass = objc_lookUpClass("NCRemotePlugIn");
    self.remotePlugIn = objc_msgSend(NCRemotePlugInClass, sel_getUid("alloc"));
    objc_msgSend(self.remotePlugIn, sel_getUid("initWithExtension:"), extension);
    
    /*
     NCWidgetHostViewController : NCRemoteViewHostViewController <NCWidgetHostProtocol>
        : NSViewController <NCRemotePlugInClient, NSRemoteViewDelegate, NCRemoteViewServiceHostProtocol>
     
     NCWidgetHostViewController is a subclass of NCRemoteViewHostViewController which itself is a subclass
     of NSViewController.
     The default constructor -[NCWidgetHostViewController initWithPlugin:(NCRemotePlugin*)remotePlugIn]
     does not override its super class implementation and is fairly straightforward.
     
     NCWidgetHostViewController conforms to NCWidgetHostProtocol
     
     Abridged pseudocode:
     self = [(NSViewController*)super initWithNibName:nil bundle:nil];
     self.remotePlugIn = remotePlugIn;
     [[self remotePlugin] setDelegate:self];
     self.identifier = [remotePlugIn identifier]; remotePlugIn.identifier = bundle id of its extension
     return self;
    */
    
    Class NCRemoteViewHostViewControllerClass = objc_lookUpClass("NCWidgetHostViewController");
    self.remoteViewHostController = objc_msgSend(NCRemoteViewHostViewControllerClass, sel_getUid("alloc"));
    objc_msgSend(self.remoteViewHostController, sel_getUid("initWithPlugin:"), self.remotePlugIn);
    objc_msgSend(self.remoteViewHostController, sel_getUid("setDelegate:"), self);
    
    self.window = [[NCWidgetWindow alloc] initWithWidgetHostViewController:self.remoteViewHostController];
    [self.window setEditButtonAction:@selector(toggleWidgetMode)];
    [self.window setEditButtonTarget:self];
    
    [self.window setTitle: objc_msgSend(self.remotePlugIn, sel_getUid("name"))];
    [self.window setIcon: objc_msgSend(self.remotePlugIn, sel_getUid("image"))];
    
    return self;
}

- (NSString*)name {
    return objc_msgSend(self.remotePlugIn, sel_getUid("name"));
}

- (NSImage*)icon {
    return objc_msgSend(self.remotePlugIn, sel_getUid("image"));
}

- (void)updateWindowSize:(CGSize)size {
    [self.window.widgetContent setFrameSize:NSSizeFromCGSize(size)];
    
    size.height += 20;
    NSRect frame = [self.window frame];
    frame.origin.y += frame.size.height;
    frame.origin.y -= size.height;
    frame.size = size;
    [self.window setFrame:NSRectFromCGRect(frame) display:YES];
}


- (void)run {
    /*
     This process is normally done by calling [NCWidgetHostViewController setActive:YES], but
     I decided to reimplement it in order to learn/show how to setup and host an NSRemoteView.
     At this point it wouldn't take too much to remove all NotificationCenter methods from
     here.
     
     [NCWidgetHostViewController setActive:] really is where all the magic happens. Here is a
     VERY abridged chain of calls happening.
     
     [NCWidgetHostViewController setActive:]
     -> [self.remotePlugIn setActivationType:2]
     --> [self _activatePlugIn]
     ---> [self.extension beginExtensionRequestWithInputItems:(empty NSArray*)
            completion:NCRemotePlugIn.blockFunc1(NSUUID* extID, NSError*)
     
     NCRemotePlugIn.blockFunc1(NSUUID* extID, NSError*)
     -> NCRemotePlugIn.blockFunc2(extID)
     --> self.extensionContext = [self.extension _extensionContextForUUID:extID]
     --> [self.extensionContext setDelegate:self.delegate]
     --> self.extensionRequestIdentifier = extID;
     --> [self _serviceAlive]
     ---> [self _notifyDelegateOfActiveStateChange:0x1]
     ----> [self.delegate remotePlugInDidActivate:self] //NCRemotePlugIns delegate is our NCWidgetHostViewController
     -----> configurationDictionary = [NSMutableDictionary dictionary]
     -----> [self remoteViewSetupConfiguration:&configurationDictionary] //modify configurationDictionary for custom appearance 
     -----> [[(NCRemotePlugIn*)arg0 proxyObject] remoteViewSetupConfiguration:configurationDictionary reply:NCWidgetHostViewController.blockFunc1()]
     
     NCWidgetHostViewController.blockFunc1()
     -> dispatch_async(dispatch_get_main_queue(), ^() {
            [[self.remotePlugIn proxyObject] remoteViewServiceChangedActiveState:1]
            [self _setupRemoteView]
        })
     
     [NCWidgetHostViewController _setupRemoteView]
     -> [self _addRemoteView]
    */
    
    //objc_msgSend(self.remoteViewHostController, sel_getUid("setActive:"), 1);
    
    [self.remotePlugIn setValue:[NSNumber numberWithInt:2] forKey:@"_activationType"];
    [self.remotePlugIn setValue:[NSNumber numberWithInt:1] forKey:@"_pluginUsing"];
    
    objc_msgSend(self.extension, sel_getUid("beginExtensionRequestWithInputItems:completion:"),
                 @[],
                 ^(NSUUID *arg0, NSError *arg1) {
                     dispatch_async(dispatch_get_main_queue(), ^() {
                         id extContext = objc_msgSend(self.extension, sel_getUid("_extensionContextForUUID:"), arg0);
                         objc_msgSend(extContext, sel_getUid("setDelegate:"),
                                      objc_msgSend(self.remotePlugIn, sel_getUid("delegate")));
                         objc_msgSend(self.remotePlugIn, sel_getUid("setExtensionContext:"), extContext);
                         [self.remotePlugIn setValue:arg0 forKey:@"_extensionRequestIdentifier"];
                         NSMutableDictionary *configDict = [NSMutableDictionary dictionary];
                         objc_msgSend(self.remoteViewHostController,
                                      sel_getUid("remoteViewSetupConfiguration:"),
                                      configDict);
                         [self remoteViewServiceConfigure:configDict];
                     });
                 }
    );
    
    [self.remoteViewHostController setValue:[NSNumber numberWithBool:YES] forKey:@"_active"];
    [self.window setIsVisible:YES];
    self.isRunning = YES;
}

- (void)remoteViewServiceConfigure:(NSDictionary*)configDict {
    objc_msgSend(objc_msgSend(self.remotePlugIn, sel_getUid("proxyObject")),
                 sel_getUid("remoteViewServiceConfigure:reply:"),
                 configDict, ^() {
                     dispatch_async(dispatch_get_main_queue(), ^() {
                         objc_msgSend(objc_msgSend(self.remotePlugIn, sel_getUid("proxyObject")),
                                      sel_getUid("remoteViewServiceChangedActiveState:"), 1);
                         [self setupRemoteView];
                     });
                 });
}

- (void)addRemoteView {
    
    NSView *contentView = [self.remoteViewHostController valueForKey:@"_contentView"];
    NSRemoteView *remoteView = [self.remoteViewHostController valueForKey:@"_remoteView"];
    
    [contentView addSubview:remoteView];
    [remoteView setTranslatesAutoresizingMaskIntoConstraints:NO];

    NSDictionary *dict = NSDictionaryOfVariableBindings(remoteView);
    NSArray *constraintsArray = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[remoteView]-0-|"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:dict];
    
    [contentView addConstraints:constraintsArray];
    
    constraintsArray = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[remoteView]-0-|"
                                                               options:0
                                                               metrics:nil
                                                                 views:dict];
    
    [contentView addConstraints:constraintsArray];
    [contentView layoutSubtreeIfNeeded];
    objc_msgSend(self.remoteViewHostController, sel_getUid("setLive:"), 1);
    [[remoteView layer] setAllowsEdgeAntialiasing:NO];
    [self remoteViewController:(NCRemoteViewHostViewController*)self.remoteViewHostController liveStatusChanged:1];
    [self.window recalculateKeyViewLoop];
}

- (void)setupRemoteView {
    objc_msgSend(self.remoteViewHostController, sel_getUid("_takeDownRemoteView"));
    
    NSRemoteView *remoteView = [[NSRemoteView alloc] initWithFrame:NSRectFromString(@"{{0,0}, {0,0}}")];
    [remoteView setDelegate:self.remoteViewHostController];
    
    NSString *pluginID = objc_msgSend(self.remotePlugIn, sel_getUid("identifier"));
    [remoteView setServiceName:[pluginID stringByAppendingString:@".viewbridge"]];
    
    NSString* serviceClass = objc_msgSend(self.remoteViewHostController, sel_getUid("remoteViewServiceClassName"));
    [remoteView setServiceSubclassName:serviceClass];
    
    objc_msgSend(remoteView, sel_getUid("setSynchronizesImplicitAnimations:"), 0);
    objc_msgSend(remoteView, sel_getUid("setTranslatesAutoresizingMaskIntoConstraints:"), 1);
    objc_msgSend(remoteView, sel_getUid("setIdentifier:"), @"remoteView");
    objc_msgSend(remoteView, sel_getUid("setShouldMaskToBounds:"), 0);
    [self.remoteViewHostController setValue:remoteView forKey:@"_remoteView"];
    objc_msgSend(remoteView, sel_getUid("advanceToConfigPhaseIfNeeded:"), ^(NSError *err) {
        NSNumber *screenNum = [self.remoteViewHostController.view.window.screen.deviceDescription objectForKeyedSubscript:@"NSScreenNumber"];
        id bridge = objc_msgSend([self.remoteViewHostController valueForKey:@"_remoteView"],
                                 sel_getUid("bridge"));
        
        NSUUID *uuid = objc_msgSend(self.remotePlugIn, sel_getUid("extensionUUID"));
        [bridge setObject:uuid forKey:@"NSExtensionUUID"];
        
        objc_msgSend(objc_msgSend(self.remotePlugIn, sel_getUid("proxyObject")),
                     sel_getUid("remoteViewServiceReadyForDisplay:block:"), screenNum,
                     ^(CGSize size, unsigned long long i, NSDictionary *config){
                         dispatch_async(dispatch_get_main_queue(), ^() {
                             [self updateWindowSize:size];
                             objc_msgSend(self.remoteViewHostController, sel_getUid("remoteViewReadyWithConfiguration:"), config);
                             [NSAnimationContext runAnimationGroup:^(NSAnimationContext*  _Nonnull ctx) {
                                 [ctx setAllowsImplicitAnimation:NO];
                                 [self addRemoteView];
                             }];
                         });
                     });
    });
}

- (void)stop {
    objc_msgSend(self.remoteViewHostController, sel_getUid("setActive:"), NO);
    [self.window setIsVisible:NO];
    self.isRunning = NO;
}

#pragma mark - NCWidgetHostViewControllerDelegate <NCRemoteViewHostViewControllerDelegate>

- (void)remoteViewController:(NCRemoteViewHostViewController *)arg1 contentSizeChanged:(struct CGSize)arg2 {
    //NSLog(@"contentSizeChanged:");
    [self updateWindowSize:arg2];
}

- (void)remoteViewController:(NCRemoteViewHostViewController *)arg1 liveStatusChanged:(BOOL)arg2; {
    //NSLog(@"liveStatusChanged:%i", arg2);
}

- (void)remoteViewController:(NCRemoteViewHostViewController *)arg1 saveSnapshotData:(NSData *)arg2 withScale:(double)arg3 dark:(BOOL)arg4 {
    //NSLog(@"saveSnapshotData:withScale:dark:");
}

- (void)remoteViewController:(NCRemoteViewHostViewController *)arg1 loadSnapshotAtScale:(double)arg2 dark:(BOOL)arg3 data:(void (^)(NSData *))arg4 {
    //NSLog(@"loadSnapshotAtScale:dark:data:");
}

- (BOOL)remoteViewControllerSupportsSnapshot:(NCRemoteViewHostViewController *)arg1 {
    //NSLog(@"remoteViewControllerSupportsSnapshot:");
    return YES;
}

- (void)remoteViewController:(NCRemoteViewHostViewController *)arg1 readyWithConfiguration:(NSDictionary *)arg2 {
    //NSLog(@"readyWithConfiguration:");
    if ([[arg2 valueForKey:@"SupportsEditing"] boolValue] == NO)
        self.window.header.editButtonView.hidden = YES;
}

- (void)widgetViewController:(NCWidgetHostViewController *)arg1 widgetModeChanged:(unsigned long long)arg2 {
    //NSLog(@"widgetModeChanged:");
    self.widgetMode = arg2;
}

- (void)widgetViewController:(NCWidgetHostViewController *)arg1 hasContentChanged:(BOOL)arg2 {
    //NSLog(@"hasContentChanged:");
}

@end
