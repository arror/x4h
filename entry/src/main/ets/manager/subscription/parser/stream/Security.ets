import { url } from "@kit.ArkTS";

export function ParseSecurity(params: url.URLParams, stream: Record<string, Object>) {

  const security = params.get("security") || 'none'
  const network = params.get('type') || 'raw'
  const host = params.get('host') || ''
  const fp = params.get("fp") || ''
  const sni = params.get("sni") || ''
  const ech = params.get("ech") || ''
  const pcs = params.get("pcs") || ''
  const vcn = params.get("vcn") || ''
  const alpn = params.get('alpn') || ''
  const allowInsecure = (params.get("insecure") || '') === '1' || (params.get("allowInsecure") || '') === '1'
  const pbk = params.get("pbk") || ''
  const sid = params.get("sid") || ''
  const pqv = params.get("pqv") || ''
  const spx = params.get("spx") || ''

  stream['security'] = security

  switch (security) {
    case 'tls':
      const tlsSettings: Record<string, Object> = {}
      stream['tlsSettings'] = tlsSettings
      tlsSettings['fingerprint'] = fp
      tlsSettings['serverName'] = sni
      if ((network === 'ws' || network === 'websocket') && host !== '' && sni === '') {
        tlsSettings['serverName'] = host
      }
      tlsSettings['echConfigList'] = ech
      tlsSettings['pinnedPeerCertSha256'] = pcs
      tlsSettings['verifyPeerCertByName'] = vcn
      if (alpn !== '') {
        tlsSettings['alpn'] = alpn.split(',')
      }
      tlsSettings['allowInsecure'] = allowInsecure
      break
    case 'reality':
      const realitySettings: Record<string, Object> = {}
      stream['realitySettings'] = realitySettings
      realitySettings['fingerprint'] = fp
      realitySettings['serverName'] = sni
      realitySettings['password'] = pbk
      realitySettings['shortId'] = sid
      realitySettings['mldsa65Verify'] = pqv
      realitySettings['spiderX'] = spx
      break
  }
}