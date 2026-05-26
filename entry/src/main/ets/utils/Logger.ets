import { hilog } from "@kit.PerformanceAnalysisKit";

export namespace Logger {

  export function debug(msg: string) {
    hilog.debug(0xFF, 'XRAY_CORE', '%{public}s', msg)
  }

  export function info(msg: string) {
    hilog.info(0xFF, 'XRAY_CORE', '%{public}s', msg)
  }

  export function warn(msg: string) {
    hilog.warn(0xFF, 'XRAY_CORE', '%{public}s', msg)
  }

  export function error(msg: string) {
    hilog.error(0xFF, 'XRAY_CORE', '%{public}s', msg)
  }

  export function fatal(msg: string) {
    hilog.fatal(0xFF, 'XRAY_CORE', '%{public}s', msg)
  }
}