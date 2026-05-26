import { Invoke } from "./Lib"

export namespace Ping {

  export function start(session: string, path: string): void {
    const map = new Map<never, never>()
    map['session'] = session
    map['path'] = path
    Invoke('PingService.Start', map)
  }

  export function stop(session: string): void {
    const map = new Map<never, never>()
    map['session'] = session
    Invoke('PingService.Stop', map)
  }
}