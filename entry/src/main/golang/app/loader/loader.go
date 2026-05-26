package loader

import (
	"encoding/json"
	"errors"
	"io"

	"github.com/xtls/xray-core/core"
	"github.com/xtls/xray-core/infra/conf"

	"harmonyos/xray/assert"
)

func init() {
	assert.Must(core.RegisterConfigLoader(&core.ConfigFormat{
		Name:      "JSON",
		Extension: []string{"json"},
		Loader: func(input any) (*core.Config, error) {
			switch v := input.(type) {
			case io.Reader:
				config := &conf.Config{}
				if err := json.Unmarshal(assert.Must2(io.ReadAll(v)), config); err == nil {
					return config.Build()
				} else {
					return nil, err
				}
			default:
				return nil, errors.New("unknown type")
			}
		},
	}))
}
