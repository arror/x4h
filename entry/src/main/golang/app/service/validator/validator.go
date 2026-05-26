package validator

import (
	"errors"
	"net"

	"harmonyos/xray/app/ipc"
)

const (
	TYPE_IP ValidateType = iota
	TYPE_IPCIDR
)

type ValidateType int

type ValidateService struct{}

type ValidateRequest struct {
	Type  ValidateType `json:"type"`
	Value string       `json:"value"`
}

type ValidateResponse struct {
	Value string `json:"value"`
}

func (s *ValidateService) Validate(req *ValidateRequest) (*ValidateResponse, error) {
	if req.Value == "" {
		return nil, errors.New("输入值不能为空")
	}
	switch req.Type {
	case TYPE_IP:
		if ip := net.ParseIP(req.Value); ip == nil {
			return nil, errors.New("IP 地址格式无效，请输入正确的 IPv4 或 IPv6 地址")
		}
	case TYPE_IPCIDR:
		if _, _, err := net.ParseCIDR(req.Value); err != nil {
			return nil, errors.New("IP CIDR 格式无效，请输入正确的格式如 192.168.1.0/24")
		}
	default:
		return nil, errors.New("未知的验证类型")
	}
	return &ValidateResponse{Value: req.Value}, nil
}

func init() {
	ipc.Register(&ValidateService{})
}
