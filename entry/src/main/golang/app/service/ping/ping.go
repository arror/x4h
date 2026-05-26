package ping

import (
	"context"
	"encoding/json"
	"net"
	"net/http"
	"net/url"
	"os"
	"sync"
	"time"

	"github.com/xtls/xray-core/common"
	"github.com/xtls/xray-core/common/errors"
	"github.com/xtls/xray-core/core"
	"github.com/xtls/xray-core/features"
	"github.com/xtls/xray-core/features/outbound"
	"github.com/xtls/xray-core/features/routing"
	"github.com/xtls/xray-core/infra/conf"
	"github.com/xtls/xray-core/transport/internet/tagged"

	xnet "github.com/xtls/xray-core/common/net"

	"harmonyos/xray/app/ipc"
	"harmonyos/xray/app/ohos/commonevent"
)

type PingService struct {
	mu        sync.Mutex
	instances map[string]*core.Instance
}

type PingStartRequest struct {
	Path    string `json:"path"`
	Session string `json:"session"`
}

type PingStopRequest struct {
	Session string `json:"session"`
}

type Config struct {
	session string
}

func (s *PingService) Start(req *PingStartRequest) (*ipc.Void, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.stop(req.Session)
	data, err := os.ReadFile(req.Path)
	if err != nil {
		return nil, err
	}
	jsonConfig := &conf.Config{}
	err = json.Unmarshal(data, jsonConfig)
	if err != nil {
		return nil, err
	}
	coreConfig, err := jsonConfig.Build()
	if err != nil {
		return nil, err
	}
	instance, err := core.New(coreConfig)
	if err != nil {
		return nil, err
	}
	instance.AddFeature(common.Must2(core.CreateObject(instance, &Config{session: req.Session})).(features.Feature))
	err = instance.Start()
	if err != nil {
		return nil, err
	}
	s.instances[req.Session] = instance
	return &ipc.Void{}, nil
}

func (s *PingService) Stop(req *PingStopRequest) (*ipc.Void, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.stop(req.Session)
	return &ipc.Void{}, nil
}

func (s *PingService) stop(session string) {
	if instance, ok := s.instances[session]; ok {
		instance.Close()
		delete(s.instances, session)
	}
}

func init() {
	ipc.Register(&PingService{instances: make(map[string]*core.Instance)})
}

func init() {
	common.Must(common.RegisterConfig((*Config)(nil), func(ctx context.Context, cfg any) (any, error) {
		var obm outbound.Manager
		var dispatcher routing.Dispatcher
		err := core.RequireFeatures(ctx, func(om outbound.Manager, rd routing.Dispatcher) {
			obm = om
			dispatcher = rd
		})
		if err != nil {
			return nil, errors.New("Cannot get depended features").Base(err)
		}
		ctx, ccl := context.WithCancel(ctx)
		return &observer{session: cfg.(*Config).session, ctx: ctx, ccl: ccl, obm: obm, dispatcher: dispatcher}, nil
	}))
}

type Result struct {
	Key   string
	Value int64
}

var _ features.Feature = (*observer)(nil)

type observer struct {
	session    string
	ctx        context.Context
	ccl        context.CancelFunc
	obm        outbound.Manager
	dispatcher routing.Dispatcher
}

func (o *observer) Type() any {
	return (*observer)(nil)
}

func (o *observer) Start() error {
	handlers := o.obm.ListHandlers(o.ctx)
	tags := make([]string, len(handlers))
	for i, handler := range handlers {
		tags[i] = handler.Tag()
	}
	go o.Ping(tags)
	return nil
}

func (o *observer) Close() error {
	o.ccl()
	return nil
}

func (o *observer) Ping(tags []string) {
	hs, ok := o.obm.(outbound.HandlerSelector)
	if !ok {
		return
	}
	outbounds := hs.Select(tags)
	o.PublishStartEvent()
	ch := make(chan Result, len(outbounds))
	for _, v := range outbounds {
		go func(v string) {
			ch <- o.Probe(v)
		}(v)
	}
	for range outbounds {
		select {
		case v := <-ch:
			o.PublishResultEvent(v.Key, v.Value)
		case <-o.ctx.Done():
			o.PublishEndEvent()
			return
		}
	}
	o.PublishEndEvent()
}

func (o *observer) Probe(outbound string) Result {
	transport := http.Transport{
		Proxy: func(*http.Request) (*url.URL, error) {
			return nil, nil
		},
		DialContext: func(ctx context.Context, network string, addr string) (net.Conn, error) {
			dest, err := xnet.ParseDestination(network + ":" + addr)
			if err != nil {
				return nil, errors.New("cannot understand address").Base(err)
			}
			conn, err := tagged.Dialer(ctx, o.dispatcher, dest, outbound)
			if err != nil {
				return nil, errors.New("cannot dial remote address ", dest).Base(err)
			}
			return conn, nil
		},
		TLSHandshakeTimeout: time.Second * 5,
	}
	client := &http.Client{
		Transport: &transport,
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return http.ErrUseLastResponse
		},
		Jar:     nil,
		Timeout: time.Second * 5,
	}
	startTime := time.Now()
	req, err := http.NewRequestWithContext(o.ctx, http.MethodGet, "https://www.google.com/generate_204", nil)
	if err != nil {
		return Result{Key: outbound, Value: 10000}
	}
	response, err := client.Do(req)
	if err != nil {
		return Result{Key: outbound, Value: 10000}
	}
	if response.Body != nil {
		response.Body.Close()
	}
	return Result{Key: outbound, Value: time.Since(startTime).Milliseconds()}
}

func (o *observer) PublishStartEvent() {
	info := commonevent.NewCommonEventPublishInfo(false)
	if info == nil {
		return
	}
	defer info.Close()
	info.SetData("START")
	commonevent.PublishCommonEventWithInfo(o.session, info)
}

func (o *observer) PublishResultEvent(outbound string, delay int64) {
	params := commonevent.NewCommonEventParameters()
	if params == nil {
		return
	}
	defer params.Close()
	params.SetString("outbound", outbound)
	params.SetLong("delay", delay)
	info := commonevent.NewCommonEventPublishInfo(false)
	if info == nil {
		return
	}
	defer info.Close()
	info.SetData("RESULT")
	info.SetParameters(params)
	commonevent.PublishCommonEventWithInfo(o.session, info)
}

func (o *observer) PublishEndEvent() {
	info := commonevent.NewCommonEventPublishInfo(false)
	if info == nil {
		return
	}
	defer info.Close()
	info.SetData("END")
	commonevent.PublishCommonEventWithInfo(o.session, info)
}
