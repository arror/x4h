package version

import (
	"github.com/xtls/xray-core/core"

	"harmonyos/xray/app/ipc"
)

type VersionService struct{}

type VersionResponse struct {
	Version string `json:"version"`
}

func (s *VersionService) GetVersion(req *ipc.Void) (*VersionResponse, error) {
	return &VersionResponse{
		Version: core.Version(),
	}, nil
}

func init() {
	ipc.Register(&VersionService{})
}
