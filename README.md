![Logo](https://github.com/fanta1ty/TProgressHUD/blob/master/Logo/Logo.png)

# TProgressHUD

[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-brightgreen)](https://developer.apple.com/swift/)
[![Version](https://img.shields.io/cocoapods/v/TProgressHUD.svg?style=flat)](https://cocoapods.org/pods/TProgressHUD)
[![License](https://img.shields.io/cocoapods/l/TProgressHUD.svg?style=flat)](https://cocoapods.org/pods/TProgressHUD)
[![Platform](https://img.shields.io/cocoapods/p/TProgressHUD.svg?style=flat)](https://cocoapods.org/pods/TProgressHUD)
[![Email](https://img.shields.io/badge/contact-@thinhnguyen12389@gmail.com-blue)](thinhnguyen12389@gmail.com)

**TProgressHUD** is a clean, lightweight, and easy-to-use HUD (Heads-Up Display) library designed to elegantly display the progress of ongoing tasks in iOS applications. Built with Swift 5, it provides a simple yet powerful API for showing loading indicators, progress bars, and status messages to enhance user experience during background operations.

## ✨ Features

- **🚀 Simple API**: Show and dismiss HUDs with just one line of code
- **📊 Progress Tracking**: Support for both indeterminate and determinate progress indicators
- **📝 Status Messages**: Display custom status text alongside progress indicators
- **⏰ Auto Dismiss**: Automatic dismissal with customizable delay
- **🎨 Clean Design**: Modern and native iOS appearance
- **🔧 Lightweight**: Minimal footprint with maximum functionality
- **📱 Thread Safe**: Safe to call from any thread
- **🎯 Easy Integration**: Drop-in replacement for other HUD libraries

## 🎯 Why TProgressHUD?

When building iOS applications, you often need to inform users about ongoing background tasks. TProgressHUD solves common problems:

- **Complex UI blocking operations** - Show users that something is happening
- **Network requests** - Indicate loading states during API calls
- **File operations** - Display progress for uploads/downloads
- **Background processing** - Keep users informed about lengthy tasks

**TProgressHUD makes this incredibly simple with a clean, modern interface that fits naturally into any iOS app.**

## 📋 Requirements

- **iOS**: 12.0+
- **Swift**: 5.0+
- **Xcode**: 11.0+

## 📦 Installation

### CocoaPods

[CocoaPods](https://cocoapods.org) is the recommended way to install TProgressHUD. Add the following line to your `Podfile`:

```ruby
pod 'TProgressHUD'
```

Then run:
```bash
pod install
```

### Swift Package Manager

Add TProgressHUD to your project through Xcode's Package Manager:

1. File → Add Package Dependencies
2. Enter package URL: `https://github.com/fanta1ty/TProgressHUD.git`
3. Select branch: `master`
4. Add to your target

Or add it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/fanta1ty/TProgressHUD.git", branch: "master")
]
```

### Manual Installation

1. Download the project files
2. Drag and drop the `TProgressHUD` source files into your Xcode project
3. Make sure to add them to your target

## 🚀 Quick Start

Using TProgressHUD in your app is as simple as:

```swift
import TProgressHUD

// Show HUD
TProgressHUD.show()

// Dismiss HUD
TProgressHUD.dismiss()
```

## 📖 Usage Guide

### Basic Loading Indicator

Show an indeterminate loading indicator:

```swift
// Simple loading indicator
TProgressHUD.show()

// With status message
TProgressHUD.showWithStatus(status: "Loading...")

// Dismiss after task completion
DispatchQueue.global(qos: .background).async {
    // Perform your background task here
    sleep(3) // Simulating work
    
    DispatchQueue.main.async {
        TProgressHUD.dismiss()
    }
}
```

### Progress Tracking

Display determinate progress for trackable tasks:

```swift
// Show progress without status
TProgressHUD.showProgress(progress: 0.0)

// Show progress with status
TProgressHUD.showProgress(progress: 0.0, status: "Uploading...")

// Update progress during task
for i in 1...100 {
    let progress = Float(i) / 100.0
    DispatchQueue.main.async {
        TProgressHUD.showProgress(progress: progress, status: "Uploading \(i)%")
    }
    Thread.sleep(forTimeInterval: 0.1) // Simulate work
}

// Dismiss when complete
TProgressHUD.dismiss()
```

### Auto Dismiss

Automatically dismiss the HUD after a specified delay:

```swift
// Show HUD and dismiss after 2 seconds
TProgressHUD.show()
TProgressHUD.dismissWithDelay(delay: 2.0)

// Show status and auto dismiss
TProgressHUD.showWithStatus(status: "Operation completed!")
TProgressHUD.dismissWithDelay(delay: 1.5)
```

## 🎨 Advanced Usage

### Network Request Example

Perfect for API calls and network operations:

```swift
func performNetworkRequest() {
    TProgressHUD.showWithStatus(status: "Fetching data...")
    
    URLSession.shared.dataTask(with: url) { data, response, error in
        DispatchQueue.main.async {
            if error != nil {
                TProgressHUD.showWithStatus(status: "Error occurred")
                TProgressHUD.dismissWithDelay(delay: 2.0)
            } else {
                TProgressHUD.showWithStatus(status: "Success!")
                TProgressHUD.dismissWithDelay(delay: 1.0)
            }
        }
    }.resume()
}
```

### File Upload with Progress

Show upload progress for file operations:

```swift
func uploadFile() {
    TProgressHUD.showProgress(progress: 0.0, status: "Preparing upload...")
    
    // Simulate file upload with progress
    let uploadTask = URLSession.shared.uploadTask(with: request, from: data) { _, _, error in
        DispatchQueue.main.async {
            if error == nil {
                TProgressHUD.showWithStatus(status: "Upload completed!")
                TProgressHUD.dismissWithDelay(delay: 1.5)
            } else {
                TProgressHUD.dismiss()
            }
        }
    }
    
    // Monitor upload progress
    uploadTask.resume()
}

// Update progress during upload (call from progress delegate)
func updateUploadProgress(_ progress: Float) {
    let percentage = Int(progress * 100)
    TProgressHUD.showProgress(progress: progress, status: "Uploading \(percentage)%")
}
```

### Multi-Step Process

Handle complex operations with multiple steps:

```swift
func performMultiStepOperation() {
    // Step 1
    TProgressHUD.showWithStatus(status: "Step 1: Initializing...")
    
    DispatchQueue.global().async {
        self.performStep1()
        
        DispatchQueue.main.async {
            // Step 2
            TProgressHUD.showWithStatus(status: "Step 2: Processing...")
        }
        
        self.performStep2()
        
        DispatchQueue.main.async {
            // Step 3
            TProgressHUD.showWithStatus(status: "Step 3: Finalizing...")
        }
        
        self.performStep3()
        
        DispatchQueue.main.async {
            TProgressHUD.showWithStatus(status: "Completed!")
            TProgressHUD.dismissWithDelay(delay: 2.0)
        }
    }
}
```

### Form Submission

Great for form validation and submission:

```swift
@IBAction func submitForm(_ sender: UIButton) {
    // Validate form
    guard validateForm() else {
        showValidationError()
        return
    }
    
    // Show progress
    TProgressHUD.showWithStatus(status: "Submitting form...")
    
    // Submit data
    submitFormData { [weak self] success in
        DispatchQueue.main.async {
            if success {
                TProgressHUD.showWithStatus(status: "Form submitted successfully!")
                TProgressHUD.dismissWithDelay(delay: 2.0)
                self?.navigateToNextScreen()
            } else {
                TProgressHUD.showWithStatus(status: "Submission failed")
                TProgressHUD.dismissWithDelay(delay: 2.0)
            }
        }
    }
}
```

## 💡 Best Practices

1. **Always call from main thread** for UI updates
2. **Use meaningful status messages** to inform users
3. **Don't overuse HUDs** - only for necessary operations
4. **Provide progress feedback** for long-running tasks
5. **Handle errors gracefully** with appropriate messages
6. **Test on different device sizes** for proper appearance
7. **Keep status messages concise** for better readability

## ⚠️ Important Notes

- **Thread Safety**: TProgressHUD can be called from any thread, but UI updates are automatically dispatched to the main thread
- **View Hierarchy**: Make sure to dismiss HUDs properly to avoid memory leaks
- **User Experience**: Use HUDs sparingly and only when necessary to avoid disrupting user flow

## 🎯 Use Cases

TProgressHUD is perfect for:

- **API Calls**: Network requests and data fetching
- **File Operations**: Upload, download, and file processing
- **Authentication**: Login, registration, and verification processes
- **Data Processing**: Complex calculations and data transformations
- **Background Tasks**: Long-running operations that require user feedback
- **Form Submissions**: User input validation and submission
- **App Initialization**: Startup processes and configuration loading

## 🔧 Example Project

To run the example project:

1. Clone the repository:
   ```bash
   git clone https://github.com/fanta1ty/TProgressHUD.git
   ```
2. Navigate to the Example directory:
   ```bash
   cd TProgressHUD/Example
   ```
3. Install dependencies:
   ```bash
   pod install
   ```
4. Open the workspace file:
   ```bash
   open TProgressHUD.xcworkspace
   ```
5. Build and run the project

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Guidelines

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🚧 Roadmap

- [ ] Carthage support
- [ ] Custom styling options
- [ ] Animation customization
- [ ] Success/Error state indicators
- [ ] Accessibility improvements
- [ ] SwiftUI support
- [ ] macOS and tvOS support
- [ ] Multiple HUD instances

## 🔍 Comparison with Alternatives

| Feature | TProgressHUD | SVProgressHUD | MBProgressHUD |
|---------|-------------|---------------|---------------|
| **Swift Native** | ✅ Pure Swift | ❌ Objective-C | ❌ Objective-C |
| **Modern iOS** | ✅ iOS 12+ | ✅ iOS 9+ | ✅ iOS 9+ |
| **Simple API** | ✅ Minimal | ✅ Comprehensive | ❌ Complex |
| **Lightweight** | ✅ Very light | ✅ Light | ❌ Heavy |
| **Thread Safe** | ✅ Yes | ✅ Yes | ⚠️ Partial |

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/fanta1ty/TProgressHUD/issues) page
2. Create a new issue with detailed information
3. Contact the maintainer at [thinhnguyen12389@gmail.com](mailto:thinhnguyen12389@gmail.com)

## 📚 Documentation

For detailed documentation and advanced usage examples, visit the [Wiki](https://github.com/fanta1ty/TProgressHUD/wiki).

## 🏆 Acknowledgments

- The iOS developer community for inspiration and feedback
- Contributors who help improve the library
- Developers who test and provide valuable feedback
- Inspired by the great work of SVProgressHUD and MBProgressHUD

## 📄 License

TProgressHUD is available under the MIT license. See the [LICENSE](https://github.com/fanta1ty/TProgressHUD/blob/master/LICENSE) file for more information.

## 👤 Author

**thinhnguyen12389**
- GitHub: [@fanta1ty](https://github.com/fanta1ty)
- Email: [thinhnguyen12389@gmail.com](mailto:thinhnguyen12389@gmail.com)

---

**Made with ❤️ for the iOS development community**

If TProgressHUD helps you create better user experiences, please consider giving it a ⭐️ on GitHub!
