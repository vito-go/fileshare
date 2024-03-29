package main

import "C"
import "encoding/json"

type CBody[T any] struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	Data    T      `json:"data,omitempty"`
}

func CharErr(errMsg string) *C.char {
	result, _ := json.Marshal(&CBody[int]{
		Code:    10000,
		Message: errMsg,
	})
	return C.CString(string(result))
}
func CharOk[T any](data T) *C.char {
	result, _ := json.Marshal(&CBody[T]{
		Code:    0,
		Message: "success",
		Data:    data,
	})
	return C.CString(string(result))
}
func CharOkMsg[T any](msg string, data T) *C.char {
	result, _ := json.Marshal(&CBody[T]{
		Code:    0,
		Message: msg,
		Data:    data,
	})
	return C.CString(string(result))
}
