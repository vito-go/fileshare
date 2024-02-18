ifeq ($(OS),Windows_NT)
 PLATFORM="Windows"
else
 ifeq ($(shell uname),Darwin)
  PLATFORM="MacOS"
 else
  PLATFORM="Unix-Like"
 endif
endif
build:
ifeq ($(OS),Windows_NT)
	make build-windows
else
 ifeq ($(shell uname),Darwin)
	echo "not supported: Darwin"
	exit 1
 else
	make build-linux
 endif
endif
clean:
	rm -rf bin/
	rm -rf server/web/
	cd fileshare_web && make clean
	cd fileshare && make clean
	@echo "clean done"

build-linux:
	cd fileshare_web && make build-web
	cp -r fileshare_web/build/web/ ./fileshare_go/server/
	cd fileshare_go && make build-so-linux
	cd fileshare && make build-linux
	cp -r fileshare/bin/ ./
	@echo "PLATFORM: $(PLATFORM) all done, look at the directory bin/"
	@echo "--------$$ ls -lha bin --------"
	@ls -lha bin
build-windows:
	cd fileshare_web && make build-web
	cp -r fileshare_web/build/web/ ./fileshare_go/server/
	cd fileshare_go && make build-so-windows
	cd fileshare && make build-windows
	cp -r fileshare/bin/ ./
	@echo "PLATFORM: $(PLATFORM) all done, look at the directory bin/"
	@echo "--------$$ ls -lha bin --------"
	@ls -lha bin

build-android:
	cd fileshare_web && make build-web
	cp -r fileshare_web/build/web/ ./fileshare_go/server/
	cd fileshare_go && make build-so-android
	cd fileshare && make build-apk
	cp -r fileshare/bin/ ./
	@echo "all done, look at the directory bin/"
	@echo "--------$$ ls -lha bin --------"
	@ls -lha bin
build-la:
	cd fileshare_web && make build-web
	cp -r fileshare_web/build/web/ ./fileshare_go/server/
	cd fileshare_go && make build-so-linux
	cd fileshare_go && make build-so-android
	cd fileshare && make build-apk
	cd fileshare && make build-linux
	cp -r fileshare/bin/ ./
	@echo "all done, look at the directory bin/"
	@echo "--------$$ ls -lha bin --------"
	@ls -lha bin
