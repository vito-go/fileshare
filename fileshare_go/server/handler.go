package server

import (
	"encoding/json"
	"fileshare/mylog"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"
)

/*class FileInfo {
  String name = '';
  bool isDir = false;
  int size = 0;
  int lastTime = 0;

  FileInfo.fromJson(Map<String, dynamic> json) {
    name = json['name'] ?? '';
    size = json['size'] ?? 0;
    lastTime = json['lastTime'] ?? 0;
  }
}
*/

type FileInfo struct {
	Name     string `json:"name"`
	Path     string `json:"path"`
	IsDir    bool   `json:"isDir"`
	Size     int64  `json:"size"`
	LastTime int64  `json:"lastTime"`
}

// boards .
func (s *Server) boardDel(w http.ResponseWriter, r *http.Request) {
	remoteHost, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		remoteHost = r.RemoteAddr
	}
	id := r.URL.Query().Get("id")
	idInt, err := strconv.ParseInt(id, 10, 64)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(err.Error()))
		return
	}
	load, ok := s.clipBoards.DeleteAndLoad(idInt)
	mylog.Info("boardDel-->", "remoteHost", remoteHost, "path", r.URL.Path, "id", id, "deleted", ok, "content", load)

}
func (s *Server) boardList(w http.ResponseWriter, r *http.Request) {
	remoteHost, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		remoteHost = r.RemoteAddr
	}
	mylog.Info("boardList-->", "remoteHost", remoteHost, "path", r.URL.Path)
	w.Header().Set("Content-Type", "application/json")
	respData := s.clipBoards.List()
	b, _ := json.Marshal(respData)
	w.Write(b)
}

// boards .
func (s *Server) boardAdd(w http.ResponseWriter, r *http.Request) {
	remoteHost, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		remoteHost = r.RemoteAddr
	}
	defer r.Body.Close()
	b, err := io.ReadAll(r.Body)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(err.Error()))
		return
	}
	if len(b) == 0 {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("empty content"))
		return
	}
	board := string(b)
	mylog.Info("boardAdd-->", "remoteHost", remoteHost, "path", r.URL.Path, "content", board)

	if len(s.clipBoards.contents) > 1024 {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("contents is too much, please delete some"))
		return
	}
	id := s.clipBoards.Add(board)
	w.Write([]byte(strconv.FormatInt(id, 10)))
}

// GetFileInfos .
func (s *Server) getFileInfos(w http.ResponseWriter, r *http.Request) {
	remoteHost, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		remoteHost = r.RemoteAddr
	}
	dir := r.URL.Query().Get("path")
	mylog.Info("getFileInfos-->", "remoteHost", remoteHost, "path", r.URL.Path, "dir", dir)
	if dir == "/" {
		dir = ""
	}
	entries, err := os.ReadDir(filepath.Join(s.rootDir, dir))
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(err.Error()))
		return
	}
	var fileInfos []FileInfo
	for _, entry := range entries {
		// filter hidden files
		if entry.Name()[0] == '.' {
			continue
		}
		fInfo, err := entry.Info()
		if err != nil {
			continue
		}
		fileInfo := FileInfo{
			Path:     filepath.Join(dir, entry.Name()),
			Name:     entry.Name(),
			IsDir:    entry.IsDir(),
			Size:     fInfo.Size(),
			LastTime: fInfo.ModTime().UnixMilli(),
		}
		fileInfos = append(fileInfos, fileInfo)
	}

	sort.Slice(fileInfos, func(i, j int) bool {
		return fileInfos[i].LastTime > fileInfos[j].LastTime
	})
	w.Header().Set("Content-Type", "application/json")

	type T struct {
		FileInfos   []FileInfo `json:"fileInfos,omitempty"`
		AllowUpload bool       `json:"allowUpload"`
	}
	respData := T{
		FileInfos:   fileInfos,
		AllowUpload: s.allowUpload,
	}
	b, _ := json.Marshal(respData)
	w.Write(b)
}

// download .
func (s *Server) download(w http.ResponseWriter, r *http.Request) {
	remoteHost, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		remoteHost = r.RemoteAddr
	}
	dir := strings.TrimPrefix(r.URL.Path, "/_download/")
	if dir == "/" {
		dir = ""
	}
	mylog.Info("download-->", "remoteHost", remoteHost, "path", r.URL.Path)
	absPath := filepath.Join(s.rootDir, dir)
	//Content-Disposition: attachment; filename="filename.jpg"
	preview := r.URL.Query().Get("preview")
	switch preview {
	case "0", "false":
		// download when it's false
		w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename=%s`, filepath.Base(absPath)))
	default:
		// default to preview in order to server as a http web server(index.html)
	}
	http.ServeFile(w, r, absPath)
	return
}

// upload
func (s *Server) upload(w http.ResponseWriter, r *http.Request) {
	if !s.allowUpload {
		mylog.Warn("upload forbidden", "remoteAddr", r.RemoteAddr, "path", r.URL.Path)
		w.WriteHeader(http.StatusForbidden)
		return
	}
	name := r.URL.Query().Get("name")
	dir := r.URL.Query().Get("dir")
	remoteHost, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		remoteHost = r.RemoteAddr
	}
	mylog.Info("upload-->", "remoteHost", remoteHost, "path", r.URL.Path, "name", name, "dir", dir)
	absPath := filepath.Join(s.rootDir, dir, name)
	_, err = os.Stat(absPath)
	if err == nil {
		// file exist,rename it {name prefix}_time_{name.ext}
		ext := filepath.Ext(name)
		preName := strings.TrimSuffix(name, ext)
		newName := fmt.Sprintf("%s_%d%s", preName, time.Now().Unix(), ext)
		absPath = filepath.Join(s.rootDir, dir, newName)
	}
	f, err := os.Create(absPath)
	if err != nil {
		mylog.Error("create file error ", "absPath", absPath, "err", err.Error())
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(err.Error()))
		return
	}
	defer func() {
		if err = f.Close(); err != nil {
			mylog.Error(err.Error())
		}
	}()
	defer func() {
		if err = r.Body.Close(); err != nil {
			mylog.Error(err.Error())
		}
	}()
	n, err := io.Copy(f, r.Body)
	if err != nil {
		mylog.Error("upload error", "remoteAddr", r.RemoteAddr, "path", r.URL.Path, "name", name, "dir", dir, "size", n, "err", err)
		return
	}
	mylog.Info("upload successfully", "remoteAddr", r.RemoteAddr, "path", r.URL.Path, "name", name, "dir", dir, "size", n)
}
