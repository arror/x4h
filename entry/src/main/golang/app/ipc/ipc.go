package ipc

import (
	"encoding/json"
	"errors"
	"fmt"
	"reflect"
	"strings"
	"sync"
)

type Request struct {
	Target     string          `json:"target"`
	Method     string          `json:"method"`
	Parameters json.RawMessage `json:"parameters"`
}

type Response struct {
	Success bool            `json:"success"`
	Result  json.RawMessage `json:"result,omitempty"`
	Error   string          `json:"error,omitempty"`
}

type Void struct{}

func Register(svc any) {
	defaultRegistry.register(svc)
}

func Invoke(req *Request) *Response {
	return defaultRegistry.call(req)
}

func ParseServiceMethod(s string) (*Request, error) {
	idx := strings.LastIndex(s, ".")
	if idx <= 0 || idx >= len(s)-1 {
		return nil, errors.New("服务格式不符合错误")
	}
	return &Request{
		Target: s[:idx],
		Method: s[idx+1:],
	}, nil
}

type methodMeta struct {
	method  reflect.Method
	inType  reflect.Type
	outType reflect.Type
}

type serviceMeta struct {
	name    string
	methods map[string]*methodMeta
	value   reflect.Value
}

type registry struct {
	services map[string]*serviceMeta
	mutex    sync.RWMutex
}

var defaultRegistry = &registry{services: make(map[string]*serviceMeta)}

func (r *registry) register(svc any) {
	v := reflect.ValueOf(svc)
	pt := v.Type()
	if pt.Kind() != reflect.Pointer {
		panic("interop: service must be a pointer to struct")
	}
	st := pt.Elem()
	if st.Kind() != reflect.Struct {
		panic("interop: service must be a pointer to struct")
	}
	name := st.Name()
	meta := &serviceMeta{
		name:    name,
		methods: make(map[string]*methodMeta),
		value:   v,
	}
	for m := range pt.Methods() {
		if !isExported(m.Name) {
			continue
		}
		if isValidMethod(m.Type) {
			meta.methods[m.Name] = &methodMeta{
				method:  m,
				inType:  m.Type.In(1),
				outType: m.Type.Out(0),
			}
		}
	}
	r.mutex.Lock()
	r.services[name] = meta
	r.mutex.Unlock()
}

func (r *registry) call(req *Request) *Response {
	r.mutex.RLock()
	svc, ok := r.services[req.Target]
	r.mutex.RUnlock()
	if !ok {
		return &Response{Success: false, Error: fmt.Sprintf("service not found: %s", req.Target)}
	}
	m, ok := svc.methods[req.Method]
	if !ok {
		return &Response{Success: false, Error: fmt.Sprintf("method not found: %s", req.Method)}
	}
	in := reflect.New(m.inType.Elem())
	if len(req.Parameters) > 0 {
		if err := json.Unmarshal(req.Parameters, in.Interface()); err != nil {
			return &Response{Success: false, Error: fmt.Sprintf("invalid params: %v", err)}
		}
	}
	out := m.method.Func.Call([]reflect.Value{svc.value, in})
	if errVal := out[1]; errVal.IsValid() && !errVal.IsNil() {
		if err, ok := errVal.Interface().(error); ok {
			return &Response{Success: false, Error: err.Error()}
		}
	}
	var result json.RawMessage
	if out[0].IsValid() && !out[0].IsNil() {
		data, err := json.Marshal(out[0].Interface())
		if err != nil {
			return &Response{Success: false, Error: fmt.Sprintf("marshal result failed: %v", err)}
		}
		result = data
	}
	return &Response{Success: true, Result: result}
}

func isExported(name string) bool {
	if len(name) == 0 {
		return false
	}
	c := name[0]
	return c >= 'A' && c <= 'Z'
}

func isValidMethod(mt reflect.Type) bool {
	if mt.NumIn() != 2 || mt.NumOut() != 2 {
		return false
	}
	if mt.In(1).Kind() != reflect.Pointer {
		return false
	}
	errorType := reflect.TypeFor[error]()
	if mt.Out(1) != errorType {
		return false
	}
	return true
}
