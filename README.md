# plumob #

Simple toolchain to facilitate mobile (and later other) development with Haxe.

## Features ##

 - [x] iOS
   - [x] Project setup
     - [x] `.xcodeproj` file
     - [x] Objective-C glue code
     - [x] `iPhoneOS` and `iPhoneSimulator` builds
   - [x] Building
     - [x] `hxcpp` for Haxe to C++ compilation
     - [x] `xcodebuild` for C++ and Objective-C compilation, linking
     - [x] `lipo` to create fat / universal binary
     - [x] `ldid` to self sign (no need for an Apple developer profile)
   - [x] Deploying to simulator
     - [x] `simctl` to install and launch app on running iOS simulator
   - [x] Deploying to phone (requires jailbreak and some setup)
     - [x] `ssh` / `scp` to phone to replace / copy app
     - [x] `ssh` / `sbutils` to launch app on phone
 - [ ] Other platforms
   - [ ] OS X
   - [ ] Android
 - [ ] Asset management
   - [ ] Auto-sync
   - [ ] Triggers to allow e.g. image resizing and processing
   - [ ] Custom triggers to allow custom actions for libraries

## Setup for iOS ##

To build apps for the iOS with plumob, you will need:

 - [`hxcpp`](https://github.com/HaxeFoundation/hxcpp) >= 3.4.193 (or latest git version)
 - OS X with Xcode >= 8.2 and SDKs for iOS and / or iOS simulator
 - [`ldid`](http://iphonedevwiki.net/index.php/Ldid) for self-signing apps if needed - after installing make sure to set the `ldid_path` environmental variable

Plumob was only tested on a vagrant box packaged with OS X Sierra, XCode 8.2, and iOS SDKs 10.2. To replicate this set up, you can download the box:

 - [`vagrant-box-osx`](https://github.com/AndrewDryga/vagrant-box-osx).

Once the dependencies are installed, clone this repository with haxelib and then build the run script:

```
haxelib git plumob https://github.com/Aurel300/plumob
cd <plumob install path>/run-src
haxe make.hxml
```

You can find out your `<plumob install path>` with `haxelib path plumob` after the first step.

With this, builds should work. The Objective-C glue code will ensure your project's `Main.main()` method is called when the app is launched. However, the window creation, as well as view / view controller initialisation is not done. Your project should do this. It is recommended to use:

 - [`hx-objc-externs`](https://github.com/Aurel300/hx-objc-externs)

See `example/` for an example iOS app.

## Usage ##

```
haxelib run plumob help
  Displays this help.

haxelib run plumob create [<project>]
  Creates a new project.

haxelib run plumob info [<project>]
  Checks and prints info about a project.

haxelib run plumob build [<target>] [<project>]
  Builds the given project target.

haxelib run plumob deploy [<target>] [<project>]
  Deploys the given project target.

haxelib run plumob test [<target>] [<project>]
  Tests the given project target.

<project> is a path to an existing directory which should
  contain the file plumob.json if it contains a project.
  If this path is not specified, it defaults to the current
  working path.

<target> is the name of a target configuration. If none
  is specified, the project default is used.
```

## `plumob.json` ##

Builds are configured with the `plumob.json` file. A default one is created with `haxelib run plumob create`.

#### Project object ####

The file should contain JSON object with the following key-value pairs:

| Key | Required | Type | Description |
| --- | -------- | ---- | ----------- |
| `name` | Yes | String | Name of the project. |
| `slug` | No | String | Name used for built executables. Should not contain spaces. Based on `name` by default. |
| `package` | Yes | String | Company / developer package. |
| `version` | No | String | Semver of the project. |
| `default-target` | No | String | Target to build when none is specified. Defaults to first target in the `targets` list. |
| `build-dir` | No | String | Directory to place target builds. Defaults to `build/`. |
| `env` | No | JSON object | Key-value environmental variables. |
| `targets` | Yes | Array of objects | Target specifications. At least one is required. |

#### `env` ###

Environmental variables recognised:

| Key | Description |
| --- | ----------- |
| `hxcpp_path` | Path to the `hxcpp` root directory. Defaults to the path obtained with `haxelib path hxcpp` |
| `ldid_path` | Path to the `ldid` binary which will be used to self-sign apps. |
| `xcode_developer_dir` | Path to Xcode's Developer directory. Defaults to: `/Applications/Xcode.app/Contents/Developer` |
| `xcode_sdk_ios` | Path to the SDK to use when building for the iOS. Defaults to: `xcode_developer_dir` + `/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS10.2.sdk` |
| `xcode_sdk_ios_sim` | Path to the SDK to use when building for the iOS simulator. Defaults to: `xcode_developer_dir` + `/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator10.2.sdk` |

#### Target specifications ####

Target specifications are also JSON objects, with the following syntax:

| Key | Required | Type | Description |
| --- | -------- | ---- | ----------- |
| `name` | Yes | String | Identifier of this target. |
| `arch` | Yes | Array of strings | Platforms to use for build. See platform list. |
| `haxelibs` | No | Array of strings | Haxelib names to use for build. |
| `build-flags-haxe` | No | Array of strings | Flags to pass to `haxe` when building. |
| `deploy` | No | Array of strings | Commands to run when deploying target. |
| `test` | No | Array of strings | Commands to run when testing target. |

#### Command syntax ####

Strings in the `deploy` and `test` arrays are interpreted as Haxe templates. The following variables are defined in the context:

| Key | Value |
| --- | ----- |
| `name`, `slug`, `package`, `env` | Same as in project object. |
| `product.path` | Relative path to the built product (e.g. `.app` for iOS). |
| `product.filename` | Filename of the built product. |

## Platform list ##

The following platforms are currently supported:

| Name | Description | Applicable keys in `env` |
| ---- | ----------- | ------------------------ |
| `ios-sim` | iOS simulator. | `xcode_developer_dir`, `xcode_ios_sdk_sim`, `ldid_path` |
| `ios-armv7`, `ios-arm64` | ARMv7 and ARM64 iOS device. | `xcode_developer_dir`, `xcode_ios_sdk`, `ldid_path` |
