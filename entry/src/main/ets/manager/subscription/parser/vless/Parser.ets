import { Parser } from "../protocol/Protocol";
import { url } from "@kit.ArkTS";
import { utils } from "../utils/utils";
import { ParseStreamSettings } from "../stream/Stream";

export class VLESSParser implements Parser {

  get scheme(): string {
    return 'vless'
  }

  parse(link: url.URL): object {
    const params = link.params
    const outbound: Record<string, Object> = {}
    outbound['protocol'] = this.scheme
    outbound['tag'] = decodeURIComponent(link.hash.replace('#', '').trim())
    const settings: Record<string, Object> = {}
    outbound['settings'] = settings
    settings['address'] = utils.parseAddress(link.hostname)
    settings['id'] = link.username
    settings['flow'] = params.get('flow') || ''
    settings['encryption'] = params.get('encryption') || 'none'
    settings['port'] = utils.parsePort(link.port)
    outbound['streamSettings'] = ParseStreamSettings(params)
    return outbound
  }
}