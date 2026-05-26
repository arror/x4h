import { JSON, url } from "@kit.ArkTS";

export function ParseNetwork(params: url.URLParams, streamSettings: Record<string, Object>) {

  const network = params.get('type') || 'raw'
  const headerType = params.get('headerType') || ''
  const path = params.get('path') || ''
  const host = params.get('host') || ''
  const mode = params.get('mode') || ''
  const authority = params.get('authority') || ''
  const serviceName = params.get('serviceName') || ''
  const extra = params.get("extra") || ''

  streamSettings['network'] = network
  switch (network) {
    case 'raw':
    case 'tcp':
      if (headerType === 'http') {
        if (path !== '') {
          const rawSettings: Record<string, Object> = {}
          const header: Record<string, Object> = {}
          rawSettings['header'] = header
          header['type'] = headerType
          const request: Record<string, Object> = {}
          header['request'] = request
          request['path'] = path.split(',')
          if (host !== '') {
            request['host'] = host.split(',')
          }
          streamSettings['rawSettings'] = rawSettings
        }
      }
      break
    case 'kcp':
    case 'mkcp':
      break
    case 'ws':
    case 'websocket':
      const wsSettings: Record<string, Object> = {}
      wsSettings['host'] = host
      wsSettings['path'] = path
      streamSettings['wsSettings'] = wsSettings
      break
    case 'grpc':
    case 'gun':
      const grpcSettings: Record<string, Object> = {}
      grpcSettings['authority'] = authority
      grpcSettings['serviceName'] = serviceName
      grpcSettings['multiMode'] = mode === 'multi'
      streamSettings['grpcSettings'] = grpcSettings
      break
    case 'httpupgrade':
      const httpupgradeSettings: Record<string, Object> = {}
      httpupgradeSettings['host'] = host
      httpupgradeSettings['path'] = path
      streamSettings['httpupgradeSettings'] = httpupgradeSettings
      break
    case 'xhttp':
    case 'splithttp':
      const xhttpSettings: Record<string, Object> = {}
      xhttpSettings['host'] = host
      xhttpSettings['path'] = path
      xhttpSettings['mode'] = mode
      if (extra !== '') {
        const extraRaw = JSON.parse(extra)
        if (extraRaw && typeof extraRaw === 'object') {
          xhttpSettings['extra'] = extraRaw
        } else {
          throw new Error('数据解析失败')
        }
      }
      streamSettings['xhttpSettings'] = xhttpSettings
      break
  }
}