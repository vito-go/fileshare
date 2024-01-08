package main

import (
	"fileshare/mylog"
	"fileshare/server"
	"flag"
	_ "github.com/vito-go/daemon"
	"os"
)

func main() {
	rootDir := flag.String("d", ".", "specify sharing directory")
	port := flag.Int64("p", 9001, "specify the port")
	upload := flag.Bool("up", true, "allow upload")
	flag.Parse()
	srv := server.NewServer(*rootDir, true, *port, *upload)
	err := srv.Start()
	if err != nil {
		mylog.Error(err.Error())
		os.Exit(1)
	}
}
