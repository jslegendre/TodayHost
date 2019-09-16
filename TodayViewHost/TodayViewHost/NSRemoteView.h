typedef NS_ENUM(unsigned char, NSViewBridgePhase) {
    NSViewBridgePhaseInvalid        = 0,
    NSViewBridgePhaseInit           = 1,
    NSViewBridgePhaseConfig         = 2,
    NSViewBridgePhaseRun            = 3
};

@class NSViewBridge;
@class NSRemoteViewMarshal;

@protocol NSRemoteViewDelegate

@optional
- (BOOL)view:(NSView *)view shouldResize:(NSSize)size;
- (void)viewDidRetreatToConfigPhase:(id)sender;
- (void)viewDidAdvanceToRunPhase:(id)sender;
- (void)viewDidInvalidate:(id)sender;
- (void)viewWillInvalidate:(id)sender;
- (id)serviceFontSmoothingBackgroundColor:(id)sender;

@end

@interface NSRemoteView : NSView

@property(nonatomic, assign) BOOL trustsServiceKeyEvents;
@property(nonatomic, readonly) BOOL serviceTrustsRemoteKeyEvents;

@property(nonatomic, readonly) NSViewBridge *bridge;
@property(nonatomic, readonly) NSSize serviceViewSize;

@property(nonatomic, retain) id <NSRemoteViewDelegate> delegate;
@property(retain) NSRemoteViewMarshal *remoteViewMarshal;
@property(nonatomic, copy) NSString *serviceSubclassName;
@property(nonatomic, copy) NSString *serviceName;

@property(nonatomic, assign) NSViewBridgePhase bridgePhase;

- (BOOL)advanceToConfigPhase;
- (BOOL)advanceToRunPhase;
- (BOOL)advanceToRunPhaseIfNeeded;

- (void)retreatToConfigPhase;
- (void)invalidate;

@end
