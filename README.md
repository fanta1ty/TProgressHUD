![Logo](https://github.com/fanta1ty/TProgressHUD/blob/master/Logo/Logo.png)

# TProgressHUD

[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-brightgreen)](https://developer.apple.com/swift/)
[![Version](https://img.shields.io/cocoapods/v/TProgressHUD.svg?style=flat)](https://cocoapods.org/pods/TProgressHUD)
[![License](https://img.shields.io/cocoapods/l/TProgressHUD.svg?style=flat)](https://cocoapods.org/pods/TProgressHUD)
[![Platform](https://img.shields.io/cocoapods/p/TProgressHUD.svg?style=flat)](https://cocoapods.org/pods/TProgressHUD)
[![Email](https://img.shields.io/badge/contact-@thinhnguyen12389@gmail.com-blue)](thinhnguyen12389@gmail.com)

`TProgressHUD` is a clean and easy-to-use HUD meant to display the progress of an ongoing task on iOS

## Requirements
- iOS 12.0+
- Swift 5

## Installation

### From CocoaPods
`TProgressHUD` is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:
```ruby
pod 'TProgressHUD'
```

Second, install `TProgressHUD` into your project:
```ruby
pod install
```
### Swift Package
`TProgressHUD` is designed for Swift 5. To depend on the logging API package, you need to declare your dependency in your `Package.swift`

```swift
.package(url: "https://github.com/fanta1ty/TProgressHUD.git", brand: "master"),
```

## Usage
Using `TProgressHUD` in your app will usually look as simple as this:
```swift
TProgressHUD.show()
TProgressHUD.dismiss()
```

### Showing the HUD

You can show the status of indeterminate tasks using one of the following:
```swift
TProgressHUD.show()
TProgressHUD.showWithStatus(status: "Status")
```

If you'd like the HUD to reflect the progress of a task, use one of these:
```swift
TProgressHUD.showProgress(progress: 0.1)
TProgressHUD.showProgress(progress: 0.1, status: "Status")
```

The HUD can be dismissed using:
```swift
TProgressHUD.dismiss()
TProgressHUD.dismissWithDelay(delay: 1.0)
```

## Author

thinhnguyen12389, thinhnguyen12389@gmail.com

## License

TProgressHUD is available under the MIT license. See the LICENSE file for more info.
