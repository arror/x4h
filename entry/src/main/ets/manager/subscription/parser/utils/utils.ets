export namespace utils {

  export function parseAddress(address: string): string {
    const trimmed = address.trim()
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      return trimmed.replace('[', '').replace(']', '')
    } else {
      return trimmed
    }
  }

  export function parsePort(portStr: string): number {
    const trimmed = portStr.trim()
    if (trimmed === '') {
      throw new Error('无端口信息')
    }
    const port = Number.parseInt(trimmed)
    if (typeof port !== 'number' || Number.isNaN(port) || port < 0 || port > 65535) {
      throw new Error('端口信息不合法')
    }
    return port
  }
}