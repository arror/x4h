import { Invoke } from "./Lib"

export namespace Validator {

  function validate(type: number, value: string): string {
    const req = new Map<never, never>()
    req['type'] = type
    req['value'] = value
    interface Response { value: string }
    const resp = Invoke('ValidateService.Validate', req) as Response
    return resp.value
  }

  export function validateIP(value: string): string {
    return validate(0, value)
  }

  export function validateIPCIDR(value: string): string {
    return validate(1, value)
  }
}