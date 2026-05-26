package main

/*
#include <stdlib.h>
*/
import "C"
import (
	"encoding/json"
	"unsafe"

	"harmonyos/xray/app/ipc"
	"harmonyos/xray/assert"
)

func main() {}

//export GoInvoke
func GoInvoke(service, parameters *C.char) *C.char {
	req, err := ipc.ParseServiceMethod(C.GoString(service))
	if err != nil {
		resp := ipc.Response{Success: false, Error: err.Error()}
		return C.CString(string(assert.Must2(json.Marshal(resp))))
	}
	req.Parameters = json.RawMessage(C.GoString(parameters))
	resp := ipc.Invoke(req)
	return C.CString(string(assert.Must2(json.Marshal(resp))))
}

//export GoFreeCString
func GoFreeCString(result *C.char) {
	C.free(unsafe.Pointer(result))
}
