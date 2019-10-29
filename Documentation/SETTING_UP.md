## Setting up the nRF Mesh library

Using CocoaPods:

**For Cocoapods(Swift):**

- Create/Update your **Podfile** with the following contents

    ```
    target 'YourAppTargetName' do
        pod 'nRFMeshProvision'
    end
    ```

- Install dependencies

    ```
    pod install
    ```

- Open the newly created `.xcworkspace`

- Import the library to any of your classes by using `import nRFMeshProvision` and begin working on your project


**For Carthage:**

- Create a new **Cartfile** in your project's root with the following contents

    ```
    github "NordicSemiconductor//IOS-nRF-Mesh-Library" ~> x.y //Replace x.y with your required version
    ```

- Build with carthage

    ```
    carthage update --platform iOS //also OSX platform is available for macOS builds
    ```

- Carthage will build the **nRFMeshProvision.framework** files in **Carthage/Build/**, 
you may now copy all those files to your project and use the library, additionally, carthade also builds **\*.dsym** files 
if you need to resymbolicate crash logs. you may want to keep those files bundled with your builds for future use.

**For Swift Package Manager:**

```swift
// swift-tools-version:5.0
import PackageDescription

let package = Package(
  name: "<Your Product Name>",
  dependencies: [
    .package(
      url: "https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library/", 
      .upToNextMajor(from: "2.0.0")
    )
  ],
  targets: [.target(name: "<Your Target Name>", dependencies: ["NordicMesh"])]
)
```

Next: [Getting started >](GETTING_STARTED.md)