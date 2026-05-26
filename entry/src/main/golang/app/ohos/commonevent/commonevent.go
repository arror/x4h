package commonevent

import (
	"unsafe"

	"github.com/ebitengine/purego"

	"harmonyos/xray/assert"
)

var (
	xCommonEventPublish               func(event uintptr) int
	xCommonEventPublishWithInfo       func(event uintptr, info uintptr) int
	xCommonEventCreatePublishInfo     func(ordered bool) uintptr
	xCommonEventDestroyPublishInfo    func(info uintptr)
	xCommonEventSetPublishInfoCode    func(info uintptr, code int32) int
	xCommonEventSetPublishInfoData    func(info uintptr, data uintptr, length uint64) int
	xCommonEventSetPublishInfoParams  func(info uintptr, param uintptr) int
	xCommonEventCreateParameters      func() uintptr
	xCommonEventDestroyParameters     func(param uintptr)
	xCommonEventSetIntToParameters    func(param uintptr, key uintptr, value int) int
	xCommonEventSetLongToParameters   func(param uintptr, key uintptr, value int64) int
	xCommonEventSetBoolToParameters   func(param uintptr, key uintptr, value bool) int
	xCommonEventSetDoubleToParameters func(param uintptr, key uintptr, value float64) int
	xCommonEventSetCharToParameters   func(param uintptr, key uintptr, value byte) int
	xCommonEventSetCharArrayToParams  func(param uintptr, key uintptr, value uintptr, num uint64) int
)

func init() {
	{
		sym := assert.Must2(purego.Dlsym(0, "OH_CommonEvent_Publish"))
		purego.RegisterFunc(&xCommonEventPublish, sym)
	}
	{
		sym := assert.Must2(purego.Dlsym(0, "OH_CommonEvent_PublishWithInfo"))
		purego.RegisterFunc(&xCommonEventPublishWithInfo, sym)
	}
	{
		sym := assert.Must2(purego.Dlsym(0, "OH_CommonEvent_CreatePublishInfo"))
		purego.RegisterFunc(&xCommonEventCreatePublishInfo, sym)
	}
	{
		sym := assert.Must2(purego.Dlsym(0, "OH_CommonEvent_DestroyPublishInfo"))
		purego.RegisterFunc(&xCommonEventDestroyPublishInfo, sym)
	}
	{
		sym := assert.Must2(purego.Dlsym(0, "OH_CommonEvent_SetPublishInfoCode"))
		purego.RegisterFunc(&xCommonEventSetPublishInfoCode, sym)
	}
	{
		sym := assert.Must2(purego.Dlsym(0, "OH_CommonEvent_SetPublishInfoData"))
		purego.RegisterFunc(&xCommonEventSetPublishInfoData, sym)
	}
	{
		sym := assert.Must2(purego.Dlsym(0, "OH_CommonEvent_SetPublishInfoParameters"))
		purego.RegisterFunc(&xCommonEventSetPublishInfoParams, sym)
	}
	{
		sym := assert.Must2(purego.Dlsym(0, "OH_CommonEvent_CreateParameters"))
		purego.RegisterFunc(&xCommonEventCreateParameters, sym)
	}
	{
		sym := assert.Must2(purego.Dlsym(0, "OH_CommonEvent_DestroyParameters"))
		purego.RegisterFunc(&xCommonEventDestroyParameters, sym)
	}
	{
		sym := assert.Must2(purego.Dlsym(0, "OH_CommonEvent_SetIntToParameters"))
		purego.RegisterFunc(&xCommonEventSetIntToParameters, sym)
	}
	{
		sym := assert.Must2(purego.Dlsym(0, "OH_CommonEvent_SetLongToParameters"))
		purego.RegisterFunc(&xCommonEventSetLongToParameters, sym)
	}
	{
		sym := assert.Must2(purego.Dlsym(0, "OH_CommonEvent_SetBoolToParameters"))
		purego.RegisterFunc(&xCommonEventSetBoolToParameters, sym)
	}
	{
		sym := assert.Must2(purego.Dlsym(0, "OH_CommonEvent_SetDoubleToParameters"))
		purego.RegisterFunc(&xCommonEventSetDoubleToParameters, sym)
	}
	{
		sym := assert.Must2(purego.Dlsym(0, "OH_CommonEvent_SetCharToParameters"))
		purego.RegisterFunc(&xCommonEventSetCharToParameters, sym)
	}
	{
		sym := assert.Must2(purego.Dlsym(0, "OH_CommonEvent_SetCharArrayToParameters"))
		purego.RegisterFunc(&xCommonEventSetCharArrayToParams, sym)
	}
}

// CommonEventError 错误码
type CommonEventError int

const (
	CommonEventErrOk                  CommonEventError = 0
	CommonEventErrPermissionError     CommonEventError = 201
	CommonEventErrInvalidParameter    CommonEventError = 401
	CommonEventErrSendingLimitExceed  CommonEventError = 1500003
	CommonEventErrNotSystemService    CommonEventError = 1500004
	CommonEventErrSendingRequestFail  CommonEventError = 1500007
	CommonEventErrInitUndone          CommonEventError = 1500008
	CommonEventErrObtainSystemParams  CommonEventError = 1500009
	CommonEventErrSubscriberNumExceed CommonEventError = 1500010
	CommonEventErrAllocMemoryFailed   CommonEventError = 1500011
)

// CommonEventParameters 公共事件参数
type CommonEventParameters struct {
	handle uintptr
}

// NewCommonEventParameters 创建参数对象
func NewCommonEventParameters() *CommonEventParameters {
	handle := xCommonEventCreateParameters()
	if handle == 0 {
		return nil
	}
	return &CommonEventParameters{handle: handle}
}

// Close 销毁参数对象
func (p *CommonEventParameters) Close() CommonEventError {
	if p == nil || p.handle == 0 {
		return CommonEventErrInvalidParameter
	}
	xCommonEventDestroyParameters(p.handle)
	p.handle = 0
	return CommonEventErrOk
}

// SetInt 设置 int 参数
func (p *CommonEventParameters) SetInt(key string, value int) CommonEventError {
	if p == nil || p.handle == 0 {
		return CommonEventErrInvalidParameter
	}
	keyBytes := append([]byte(key), 0)
	return CommonEventError(xCommonEventSetIntToParameters(p.handle, uintptr(unsafe.Pointer(&keyBytes[0])), value))
}

// SetLong 设置 long 参数
func (p *CommonEventParameters) SetLong(key string, value int64) CommonEventError {
	if p == nil || p.handle == 0 {
		return CommonEventErrInvalidParameter
	}
	keyBytes := append([]byte(key), 0)
	return CommonEventError(xCommonEventSetLongToParameters(p.handle, uintptr(unsafe.Pointer(&keyBytes[0])), value))
}

// SetBool 设置 bool 参数
func (p *CommonEventParameters) SetBool(key string, value bool) CommonEventError {
	if p == nil || p.handle == 0 {
		return CommonEventErrInvalidParameter
	}
	keyBytes := append([]byte(key), 0)
	return CommonEventError(xCommonEventSetBoolToParameters(p.handle, uintptr(unsafe.Pointer(&keyBytes[0])), value))
}

// SetDouble 设置 double 参数
func (p *CommonEventParameters) SetDouble(key string, value float64) CommonEventError {
	if p == nil || p.handle == 0 {
		return CommonEventErrInvalidParameter
	}
	keyBytes := append([]byte(key), 0)
	return CommonEventError(xCommonEventSetDoubleToParameters(p.handle, uintptr(unsafe.Pointer(&keyBytes[0])), value))
}

// SetChar 设置 char 参数
func (p *CommonEventParameters) SetChar(key string, value byte) CommonEventError {
	if p == nil || p.handle == 0 {
		return CommonEventErrInvalidParameter
	}
	keyBytes := append([]byte(key), 0)
	return CommonEventError(xCommonEventSetCharToParameters(p.handle, uintptr(unsafe.Pointer(&keyBytes[0])), value))
}

// SetString 设置 string 参数
func (p *CommonEventParameters) SetString(key string, value string) CommonEventError {
	if p == nil || p.handle == 0 {
		return CommonEventErrInvalidParameter
	}
	keyBytes := append([]byte(key), 0)
	valueBytes := append([]byte(value), 0)
	return CommonEventError(xCommonEventSetCharArrayToParams(p.handle, uintptr(unsafe.Pointer(&keyBytes[0])), uintptr(unsafe.Pointer(&valueBytes[0])), uint64(len(valueBytes))))
}

// CommonEventPublishInfo 公共事件发布信息
type CommonEventPublishInfo struct {
	handle uintptr
}

// NewCommonEventPublishInfo 创建发布信息对象
func NewCommonEventPublishInfo(ordered bool) *CommonEventPublishInfo {
	handle := xCommonEventCreatePublishInfo(ordered)
	if handle == 0 {
		return nil
	}
	return &CommonEventPublishInfo{handle: handle}
}

// Close 销毁发布信息对象
func (info *CommonEventPublishInfo) Close() CommonEventError {
	if info == nil || info.handle == 0 {
		return CommonEventErrInvalidParameter
	}
	xCommonEventDestroyPublishInfo(info.handle)
	info.handle = 0
	return CommonEventErrOk
}

// SetCode 设置事件 code
func (info *CommonEventPublishInfo) SetCode(code int32) CommonEventError {
	if info == nil || info.handle == 0 {
		return CommonEventErrInvalidParameter
	}
	return CommonEventError(xCommonEventSetPublishInfoCode(info.handle, code))
}

// SetData 设置事件 data
func (info *CommonEventPublishInfo) SetData(data string) CommonEventError {
	if info == nil || info.handle == 0 {
		return CommonEventErrInvalidParameter
	}
	dataBytes := append([]byte(data), 0)
	return CommonEventError(xCommonEventSetPublishInfoData(info.handle, uintptr(unsafe.Pointer(&dataBytes[0])), uint64(len(dataBytes))))
}

// SetParameters 设置事件 parameters
func (info *CommonEventPublishInfo) SetParameters(params *CommonEventParameters) CommonEventError {
	if info == nil || info.handle == 0 || params == nil || params.handle == 0 {
		return CommonEventErrInvalidParameter
	}
	return CommonEventError(xCommonEventSetPublishInfoParams(info.handle, params.handle))
}

// CommonEvent 公共事件发布器
type CommonEvent struct{}

// Publish 发布公共事件 (简单发布)
func (c *CommonEvent) Publish(event string) CommonEventError {
	eventBytes := append([]byte(event), 0)
	return CommonEventError(xCommonEventPublish(uintptr(unsafe.Pointer(&eventBytes[0]))))
}

// PublishWithInfo 发布公共事件 (带发布信息)
func (c *CommonEvent) PublishWithInfo(event string, info *CommonEventPublishInfo) CommonEventError {
	if info == nil || info.handle == 0 {
		return CommonEventErrInvalidParameter
	}
	eventBytes := append([]byte(event), 0)
	return CommonEventError(xCommonEventPublishWithInfo(uintptr(unsafe.Pointer(&eventBytes[0])), info.handle))
}

// 默认发布器实例
var defaultCommonEvent = &CommonEvent{}

// PublishCommonEvent 发布公共事件 (使用默认发布器)
func PublishCommonEvent(event string) CommonEventError {
	return defaultCommonEvent.Publish(event)
}

// PublishCommonEventWithInfo 发布公共事件 (使用默认发布器)
func PublishCommonEventWithInfo(event string, info *CommonEventPublishInfo) CommonEventError {
	return defaultCommonEvent.PublishWithInfo(event, info)
}
