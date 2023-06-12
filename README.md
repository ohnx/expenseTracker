# expenseTracker

expense tracker iphone + watch app built in like 11 hours some random saturday (edit: +another 2 hours on sunday).
thanks to swiftui for making things fast to build, but also no thanks to swiftui for causing headaches with updating data and stuff.
at least now i can say i sort of understand the update model in swift - enough to hack my things to work.

## target

i made this in Xcode Version 14.3.1 (14E300c) in June 10&11, 2023. So whatever version of Swift/iOS/watchOS was out at the time is the version I targeted (iOS 16 I think). Sorry if you're on an older version.

## how does it work?

libraries/stuff used:

* `SwiftUI`: yeah on the tin it does use SwiftUI but probably not in very "good" ways. Still might be fun to look through the code (see `ContentView.swift` files in the app itself + watch app) to laugh at it, though.
* `WatchConnectivity`: probably a decent example of how to use this library tbh. I do things the "right" way, I think. See `WatchCommunication.swift` for the bulk of this code. The phone sends an application context (containing the list of categories for expenses) to the watch (which is stored in a currentvaluesubject from combine) by serializing a data structure into JSON (was unable to get it working just sending the data structure itself). This is cool because it means the watch app doesn't need to be open at the time of the sending. The watch sends messages to the phone app (containing data on each expense that gets added through the watch app), formatted as JSON again, which i think wakes up the phone app in the background or something like that in order to process the requests, which is good.
* `Combine`: i use `PassthroughSubject` and `CurrentValueSubject` a bit as part of `WatchCommunication.swift`. I think it's a reasonably sane usage of it.
* `CoreData`: again, on paper i technically use coredata, but not really in a super proper way, probably. 

swift code is generally pretty self-documenting imo, but i do have a few misc comments scattered around if you do choose to go reading through.

oh also i made a numpad entry for the watch that is in its own separate file (`WatchNumpadView.swift`) if it's helpful for anyone.

## does it work?

untested on real devices because my watch auto-updated to the latest watchos which i unfortunately do not have the device support package for right now :/ but on the phone it seems to work fine enough:

![image](https://media.discordapp.net/attachments/502683711339364354/1117507141171957821/image.png?width=518&height=1122)
![image](https://media.discordapp.net/attachments/502683711339364354/1117507141411016734/image.png?width=518&height=1122)
![image](https://github.com/ohnx/expenseTracker/assets/6683648/80ff9bcf-f081-4bb7-a90c-90efa82fdd25)
