package core

import (
	"bytes"
	"os"
	"path/filepath"
	"runtime"
	"runtime/debug"
	"strconv"
	"sync"
	"time"

	appLog "github.com/xtls/xray-core/app/log"
	common "github.com/xtls/xray-core/common"
	commonLog "github.com/xtls/xray-core/common/log"
	platform "github.com/xtls/xray-core/common/platform"
	core "github.com/xtls/xray-core/core"

	"harmonyos/xray/app/ipc"
)

type CoreService struct {
	mu       sync.Mutex
	instance *core.Instance
}

type CoreStartRequest struct {
	Fd             int    `json:"fd"`
	AssetLocation  string `json:"assetLocation"`
	ConfigLocation string `json:"configLocation"`
}

func (s *CoreService) Start(req *CoreStartRequest) (*ipc.Void, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.instance != nil {
		if s.instance.IsRunning() {
			if err := s.instance.Close(); err != nil {
				return nil, err
			}
		}
		s.instance = nil
		runtime.GC()
	}
	os.Setenv(platform.AssetLocation, req.AssetLocation)
	os.Setenv(platform.TunFdKey, strconv.FormatInt(int64(req.Fd), 10))
	data, err := os.ReadFile(req.ConfigLocation)
	if err != nil {
		return nil, err
	}
	config, err := core.LoadConfig("json", bytes.NewReader(data))
	if err != nil {
		return nil, err
	}
	common.Must(appLog.RegisterHandlerCreator(appLog.LogType_File, func(_ appLog.LogType, options appLog.HandlerCreatorOptions) (commonLog.Handler, error) {
		fp := filepath.Join(options.Path, time.Now().Format("2006-1-2_15:04:05")+".txt")
		return commonLog.NewLogger(common.Must2(commonLog.CreateFileLogWriter(fp))), nil
	}))
	s.instance, err = core.New(config)
	if err != nil {
		return nil, err
	}
	err = s.instance.Start()
	if err != nil {
		return nil, err
	}
	runtime.GC()
	debug.FreeOSMemory()
	return &ipc.Void{}, nil
}

func init() {
	ipc.Register(&CoreService{})
}
