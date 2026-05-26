import { JSON, url } from "@kit.ArkTS";

export function ParseFinalMask(params: url.URLParams, streamSettings: Record<string, Object>) {
  const fm = params.get("fm") || ''
  if (fm !== '') {
    const fmJson = JSON.parse(fm)
    if (fmJson && typeof fmJson === 'object') {
      streamSettings['finalmask'] = fmJson
    } else {
      throw new Error('数据解析失败')
    }
  }
}