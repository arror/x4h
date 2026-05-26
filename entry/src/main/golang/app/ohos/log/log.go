package log

import (
	"log"
	"unsafe"

	"github.com/ebitengine/purego"

	"harmonyos/xray/assert"
)

var (
	xLogPrintMsg func(logType int, level int, domain uint32, tag uintptr, message uintptr) int
)

func PrintMsg(p []byte) (n int, err error) {
	if len(p) == 0 {
		return 0, nil
	}
	msg := append(p, 0)
	tag := append([]byte("X4H"), 0)
	xLogPrintMsg(0, 4, 0xFF, uintptr(unsafe.Pointer(&tag[0])), uintptr(unsafe.Pointer(&msg[0])))
	return len(p), nil
}

type HiLog struct{}

func (w *HiLog) Write(p []byte) (n int, err error) {
	return PrintMsg(p)
}

func init() {
	{
		sym := assert.Must2(purego.Dlsym(0, "OH_LOG_PrintMsg"))
		purego.RegisterFunc(&xLogPrintMsg, sym)
	}
	log.SetOutput(&HiLog{})
}
