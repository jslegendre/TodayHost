//
//  NCWidget.h
//  TodayViewHost
//
//  Created by https://github.com/jslegendre on 9/11/19.
//  Copyright © 2019 Jeremy Legendre. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Protocols.h"

NS_ASSUME_NONNULL_BEGIN
@class NCWidgetWindow;

@interface NCWidget : NSObject <NCWidgetHostViewControllerDelegate>
@property (strong) NCWidgetWindow *window;
@property (weak) id remotePlugIn;
@property (weak) __kindof NSViewController *remoteViewHostController;
@property BOOL isRunning;
@property unsigned long long widgetMode;

-(instancetype)initWithExtension:(id)extension;
- (NSString*)name;
- (NSImage*)icon;
- (void)run;
- (void)stop;

- (void)toggleWidgetMode;
@end


NS_ASSUME_NONNULL_END
