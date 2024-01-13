mkdir:
	mkdir -p android/app/jniLibs/arm64-v8a
	mkdir -p android/app/jniLibs/armeabi-v7a
	mkdir -p android/app/jniLibs/x86_64

build-all:build-apk build-linux
build-apk:
	- mkdir bin
	flutter build apk  --target-platform android-arm64
	mv build/app/outputs/flutter-apk/app-release.apk ./bin/fileshare-arm64-v8a-release.apk
build-linux:
	flutter build linux
	cp -r build/linux/x64/release/bundle/* linux-deb/opt/fileshare/
	cp  lib/*.so linux-deb/opt/fileshare/lib/
	cp  linux-deb/logo.png linux-deb/opt/fileshare/
	- mkdir bin
	dpkg -b linux-deb/ bin/fileshare.deb
build-windows:
	flutter build windows
	- mkdir  build/windows/x64/runner/Release/lib/
	cp  lib/*_windows.so  build/windows/x64/runner/Release/lib/
	- mkdir bin
	rm -rf bin/fileshare-windows
	cp -r build/windows/x64/runner/Release bin/fileshare-windows
clean:
	rm -rf bin
	rm -rf linux-deb/opt/fileshare/*
	flutter clean
