package main

// #include <stdlib.h>
import "C"
import (
	"time"
)

func main() {

}

func init() {
	// flutter 中的日志是 UTC 时间，所以这里要设置时区
	time.Local = time.FixedZone("CST", 8*3600)
}
