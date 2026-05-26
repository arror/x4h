import { JSON } from '@kit.ArkTS'
import interop from 'libinterop.so'
import { Logger } from '../utils/Logger'

export function Invoke(service: string, params: object): object {
  try {
    const parameters = JSON.stringify(params)
    const value = interop.Invoke(service, parameters)
    Logger.debug(`
    ------------------------------------------------------------------------------------
    请求: ${service}
    参数: ${parameters}
    返回: ${value}
    ------------------------------------------------------------------------------------
    `)
    interface Response {
      success: boolean
      result: object
      error: string
    }
    const response = JSON.parse(value) as Response
    if (response.success) {
      return response.result
    } else {
      throw new Error(response.error)
    }
  } catch (err) {
    Logger.error(err)
    throw err as Error
  }
}