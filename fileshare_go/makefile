ifeq ($(OS),Windows_NT)
 PLATFORM="Windows"
else
 ifeq ($(shell uname),Darwin)
  PLATFORM="MacOS"
 else
  PLATFORM="Unix-Like"
 endif
endif
all1:
	@echo $(PLATFORM)

#// different platform must specify the compile platform, or flutter will report error: for example, open android so in linux,
#// report cannot open shared object file: No such file or directory

# Important: Please set the CC environment variable to the compiler of your platform.
# e.g.
# CC=~/Android/Sdk/ndk/25.2.9519653/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android33-clang
# Or
# export PATH="$HOME/Android/Sdk/ndk/25.2.9519653/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
CC=aarch64-linux-android33-clang
 	# if not set CC, will report error:
	# runtime/cgo
	#gcc_android.c:6:10: fatal error: android/log.h: No such file or directory
	#    6 | #include <android/log.h>
	#      |          ^~~~~~~~~~~~~~~
	#compilation terminated.
cp-web:
	cp  -r ../fileshare_web/build/web server/
build-so-linux: cp-web
	@echo "build so for linux platform"
	@go build -buildmode=c-shared -ldflags="-s -w" -o ../fileshare/lib/libgo_linux.so ./cmd/flutter/
	@echo "build .so for linux platform successfully"
build-so-windows: cp-web
	@echo "build so for windows platform"
	go build -buildmode=c-shared -ldflags="-s -w" -o ../fileshare/lib/libgo_windows.so ./cmd/flutter/
	@echo "build .so for windows platform successfully"
build-so-android: cp-web
	@echo "build .so for android platform"
	@CC=${CC} GOOS=android CGO_ENABLED=1 GOARCH=arm64 go build -buildmode=c-shared -ldflags="-s -w" -o ../fileshare/android/app/jniLibs/arm64-v8a/libgo.so ./cmd/flutter/
	@echo "build .so for android platform successfully"
