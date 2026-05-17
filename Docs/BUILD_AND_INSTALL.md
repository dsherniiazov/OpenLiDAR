# Build And Install Notes

## Fix: App Cannot Be Installed Because Integrity Could Not Be Verified

If the app install fails with an error mentioning `XCUnit.framework`, `XCTest.framework`, or `OpenLidarTests.xctest`, the device is receiving a test-host app bundle instead of a normal app bundle.

This can happen after running `build-for-testing` into the same DerivedData directory that Xcode later uses for Run.

Steps:

1. In Xcode, use `Product > Clean Build Folder`.
2. Delete the app from the iPhone.
3. If it still fails, delete this folder:

```sh
rm -rf ~/Library/Developer/Xcode/DerivedData/OpenLidar-*
```

4. Run the `OpenLidar` app scheme again, not the test action.

For command-line work, keep app builds and test builds separated:

```sh
Scripts/build_app.sh
Scripts/build_tests.sh
```

The scripts use separate DerivedData folders under `.derived/` so test frameworks do not get embedded into the device app bundle.

