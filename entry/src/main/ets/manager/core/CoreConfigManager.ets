import { PersistenceV2 } from "@kit.ArkUI"
import { FileUtil } from "@pura/harmony-utils"

export enum CoreLogLevel {
  NONE = 'none',
  DEBUG = 'debug',
  INFO = 'info',
  WARNING = 'warning',
  ERROR = 'error'
}

export const CoreLogLevels: Array<CoreLogLevel> = [
  CoreLogLevel.NONE,
  CoreLogLevel.DEBUG,
  CoreLogLevel.INFO,
  CoreLogLevel.WARNING,
  CoreLogLevel.ERROR,
]

export function CoreLogLevelNameOf(level: CoreLogLevel): string {
  switch (level) {
    case CoreLogLevel.NONE:
      return '关闭'
    case CoreLogLevel.DEBUG:
      return '调试'
    case CoreLogLevel.INFO:
      return '信息'
    case CoreLogLevel.WARNING:
      return '警告'
    case CoreLogLevel.ERROR:
      return '错误'
  }
}

export enum CoreLogAddressMask {
  NONE = '',
  HALF = 'half',
  QUARTER = 'quarter',
  FULL = 'full'
}

export const CoreLogAddressMasks: Array<CoreLogAddressMask> = [
  CoreLogAddressMask.NONE,
  CoreLogAddressMask.HALF,
  CoreLogAddressMask.QUARTER,
  CoreLogAddressMask.FULL
]

export function CoreLogAddressMaskNameOf(mask: CoreLogAddressMask): string {
  switch (mask) {
    case CoreLogAddressMask.NONE:
      return '关闭'
    case CoreLogAddressMask.HALF:
      return '二分之一'
    case CoreLogAddressMask.QUARTER:
      return '四分之三'
    case CoreLogAddressMask.FULL:
      return '全部'
  }
}

@ObservedV2
export class CoreConfigLog {

  @Trace level: CoreLogLevel = CoreLogLevel.WARNING
  @Trace addressMask: CoreLogAddressMask = CoreLogAddressMask.NONE

  private static instance: CoreConfigLog | undefined
  private static storeKey: string = 'CORE_CONFIG_LOG_V1'

  static getInstance(): CoreConfigLog {
    if (CoreConfigLog.instance === undefined) {
      CoreConfigLog.instance = PersistenceV2.globalConnect({
        type: CoreConfigLog,
        key: CoreConfigLog.storeKey,
        defaultCreator: () => new CoreConfigLog()
      })!
    }
    return CoreConfigLog.instance
  }

  buildRawConfig(): object {
    interface LogObject {
      access: string
      error: string
      loglevel: string
      dnsLog: boolean
      maskAddress: string
    }
    return {
      access: 'none',
      error: FileUtil.getFilesDirPath('log'),
      loglevel: this.level,
      dnsLog: false,
      maskAddress: this.addressMask
    } as LogObject
  }
}

export enum CoreOutboundStrategy {
  RULE = 0,
  GLOBAL = 1
}

export const CoreOutboundStrategies: Array<CoreOutboundStrategy> = [
  CoreOutboundStrategy.RULE,
  CoreOutboundStrategy.GLOBAL
]

export function CoreOutboundStrategyNameOf(strategy: CoreOutboundStrategy): string {
  switch (strategy) {
    case CoreOutboundStrategy.RULE:
      return '规则'
    case CoreOutboundStrategy.GLOBAL:
      return '全局'
  }
}

@ObservedV2
export class CoreConfigOutbound {

  @Trace strategy: CoreOutboundStrategy = CoreOutboundStrategy.RULE

  private static instance: CoreConfigOutbound | undefined
  private static storeKey: string = 'CORE_CONFIG_OUTBOUND_V1'

  static getInstance(): CoreConfigOutbound {
    if (CoreConfigOutbound.instance === undefined) {
      CoreConfigOutbound.instance = PersistenceV2.globalConnect({
        type: CoreConfigOutbound,
        key: CoreConfigOutbound.storeKey,
        defaultCreator: () => new CoreConfigOutbound()
      })!
    }
    return CoreConfigOutbound.instance
  }
}

export class CoreConfigManager {

  readonly log = CoreConfigLog.getInstance()
  readonly outbound = CoreConfigOutbound.getInstance()

  private static instance: CoreConfigManager | undefined

  static getInstance(): CoreConfigManager {
    if (CoreConfigManager.instance === undefined) {
      CoreConfigManager.instance = new CoreConfigManager()
    }
    return CoreConfigManager.instance
  }
}