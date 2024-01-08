package main

import "C"
import (
	"fileshare/mylog"
	"fileshare/server"
	"sync"
	"sync/atomic"
	"time"
)

// serverIdxGlobal: generate serverIdx
var serverIdxGlobal = atomic.Int64{}

// serverIdxSyncMap: key: int64, value: *server.Server. store serverIdx and server instance in order to close server
var serverIdxSyncMap = sync.Map{}

//export StartServer
func StartServer(rootDir *C.char, allowUpload bool, port int64) int64 {
	rootDirStr := C.GoString(rootDir)
	srv := server.NewServer(rootDirStr, true, port, allowUpload)
	var chanErr = make(chan error, 1)
	go func() {
		err := srv.Start()
		if err != nil {
			mylog.Error("Server Start error", `err`, err.Error())
			select {
			case chanErr <- err:
			default:
			}
		}
	}()
	select {
	case err := <-chanErr:
		mylog.Error("Start Server error", `err`, err.Error())
		return 0
	case <-time.After(time.Millisecond * 256):
		serverIdx := serverIdxGlobal.Add(1)
		serverIdxSyncMap.Store(serverIdx, srv)
		mylog.Info("StartServer success", `port`, port, `allowUpload`, allowUpload, `serverIdx`, serverIdx)
		return serverIdx
	}

}

//export CloseServer
func CloseServer(serverIdx int64) {
	if serverIdx == 0 {
		mylog.Info("Close All Server All", `serverIdx`, 0)
		serverIdxSyncMap.Range(func(key, value interface{}) bool {
			if srv, ok := value.(*server.Server); ok {
				mylog.Info("Close Server", `serverIdxKey`, key, "port", srv.Port())
				go srv.Close()
			}
			serverIdxSyncMap.Delete(key)
			return true
		})
		return
	}
	if v, ok := serverIdxSyncMap.LoadAndDelete(serverIdx); ok {
		if srv, ok := v.(*server.Server); ok {
			mylog.Info("Clos eServer", `serverIdx`, serverIdx, "port", srv.Port())
			go srv.Close()
		}
	}
}
