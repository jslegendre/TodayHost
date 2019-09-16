@class NCRemoteViewHostViewController, NSData, NSDictionary;
@protocol NCRemoteViewHostViewControllerDelegate <NSObject>
- (void)remoteViewController:(NCRemoteViewHostViewController *)arg1 contentSizeChanged:(struct CGSize)arg2;
- (void)remoteViewController:(NCRemoteViewHostViewController *)arg1 liveStatusChanged:(BOOL)arg2;

@optional
- (void)remoteViewController:(NCRemoteViewHostViewController *)arg1 saveSnapshotData:(NSData *)arg2 withScale:(double)arg3 dark:(BOOL)arg4;
- (void)remoteViewController:(NCRemoteViewHostViewController *)arg1 loadSnapshotAtScale:(double)arg2 dark:(BOOL)arg3 data:(void (^)(NSData *))arg4;
- (BOOL)remoteViewControllerSupportsSnapshot:(NCRemoteViewHostViewController *)arg1;
- (void)remoteViewController:(NCRemoteViewHostViewController *)arg1 readyWithConfiguration:(NSDictionary *)arg2;
@end

@class NCWidgetHostViewController;
@protocol NCWidgetHostViewControllerDelegate <NCRemoteViewHostViewControllerDelegate>
- (void)widgetViewController:(NCWidgetHostViewController *)arg1 widgetModeChanged:(unsigned long long)arg2;
- (void)widgetViewController:(NCWidgetHostViewController *)arg1 hasContentChanged:(BOOL)arg2;
@end
