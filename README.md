# TodayHost
NSExtension and NSRemoteView example by hosting Notification Center widgets/Today Extensions

This is a completely standalone host for Notification Center widgets/Today Extensions (it seems even AAPL goes back and forth on what to call them).  This was an exercise to learn about NSExtensions and hosting remote views (and an opportunity to reverse Notification Center).  NotificationCenter.framework abstracts a lot of the technical stuff but I have tried my best to reimplement the important stuff as well as add PLENTY of comments. Enjoy.

## Disclaimer
Due to some entitlement issues, you will need to have the `amfi_get_out_of_my_way=1` boot-arg set in order to run this and the main reason why I chose not to continue on making this a production level app. The code here should be used as a reference/example

## Eye Candy
<img src="https://i.imgur.com/uE4xJMM.png" width="200"/>|<img src="https://i.imgur.com/tAkS2t6.png" width="200"/>| <img src="https://i.imgur.com/nQXincI.png" width="200"/>|<img src="https://i.imgur.com/gOMUGJS.jpg" width="200"/>
