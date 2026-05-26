package time

import (
	"errors"
	"time"
	"unsafe"

	"github.com/ebitengine/purego"

	"harmonyos/xray/assert"
)

var (
	xGetTimeZone func(buf uintptr, bufSize uint64) int
)

func init() {
	{
		sym := assert.Must2(purego.Dlsym(0, "OH_TimeService_GetTimeZone"))
		purego.RegisterFunc(&xGetTimeZone, sym)
	}
}

func GetTimeZone() (string, error) {
	buf := make([]byte, 64)
	ret := xGetTimeZone(uintptr(unsafe.Pointer(&buf[0])), 64)
	if ret == 0 {
		for i, b := range buf {
			if b == 0 {
				return string(buf[:i]), nil
			}
		}
	}
	return "", errors.ErrUnsupported
}

func init() {
	time.Local = assert.Must2(time.LoadLocation(assert.Must2(GetTimeZone())))
}
