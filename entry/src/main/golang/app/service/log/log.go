package log

import (
	"harmonyos/xray/assert"
	"log"

	appLog "github.com/xtls/xray-core/app/log"
	commonLog "github.com/xtls/xray-core/common/log"
)

type ConsoleLogger struct{}

func (l *ConsoleLogger) Handle(msg commonLog.Message) {
	log.Println(msg)
}

func init() {
	assert.Must(appLog.RegisterHandlerCreator(appLog.LogType_Console, func(_ appLog.LogType, _ appLog.HandlerCreatorOptions) (commonLog.Handler, error) {
		return &ConsoleLogger{}, nil
	}))
}
