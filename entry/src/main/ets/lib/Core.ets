import { Invoke } from "./Lib"

export namespace Core {

  export interface RunRequest {
    fd: number,
    assetLocation: string
    configLocation: string
  }

  export function run(req: RunRequest): void {
    Invoke('CoreService.Start', req)
  }

  export function version(): string {
    interface Response { version: string }
    const resp = Invoke('VersionService.GetVersion', new Map()) as Response
    return resp.version
  }
}