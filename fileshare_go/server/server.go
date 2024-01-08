package server

import (
	"context"
	"embed"
	"fileshare/mylog"
	"fmt"
	"io/fs"
	"net"
	"net/http"
	"path/filepath"
	"runtime"
	"sync"
	"sync/atomic"
)

//go:embed web
var content embed.FS

type Server struct {
	rootDir     string
	allowUpload bool
	port        int64
	embedded    bool
	srv         *http.Server
	clipBoards  ClipBoards
}

// Port .
func (s *Server) Port() int64 {
	return s.port
}
func NewServer(rootDir string, embedded bool, port int64, allowUpload bool) *Server {
	srv := &Server{rootDir: rootDir, embedded: embedded, port: port, allowUpload: allowUpload, clipBoards: ClipBoards{
		mux:      sync.RWMutex{},
		increId:  atomic.Int64{},
		contents: nil,
	}}
	return srv
}

// Close .
func (s *Server) Close() {
	if s.srv == nil {
		return
	}
	s.srv.Shutdown(context.Background())
}

type fileHandler struct {
	content embed.FS
}

func (f fileHandler) Open(name string) (fs.File, error) {
	// 在windows系统下必须用toSlash 封装一下路径，否则，web\index.html!=web/index.html
	name = filepath.ToSlash(filepath.Join("web", name))
	return f.content.Open(name)
}

func (s *Server) Start() error {
	mux := http.NewServeMux()
	mux.HandleFunc("/_fileInfos", s.getFileInfos)
	mux.HandleFunc("/_download/", s.download)
	mux.HandleFunc("/_upload", s.upload)
	mux.HandleFunc("/_board/list", s.boardList)
	mux.HandleFunc("/_board/add", s.boardAdd)
	mux.HandleFunc("/_board/delete", s.boardDel)

	if s.embedded {
		mux.Handle("/", http.FileServer(http.FS(&fileHandler{content: content})))
	} else {
		_, file, _, ok := runtime.Caller(0)
		if ok {
			dir := filepath.Join(filepath.Dir(file), "../../fileshare_web/build/web")
			mylog.Info("root dir", "embedded", s.embedded, "dir", dir)
			mux.Handle("/", http.FileServer(http.Dir(dir)))
		}
	}
	srv := &http.Server{Handler: mux}
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", s.port))
	if err != nil {
		return err
	}
	s.srv = srv
	return srv.Serve(lis)
}
