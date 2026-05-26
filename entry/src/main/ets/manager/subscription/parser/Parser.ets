import { VLESSParser } from './vless/Parser'
import { Parser } from './protocol/Protocol'
import { JSON, url } from '@kit.ArkTS'
import { Base64Util, StrUtil } from '@pura/harmony-utils'
import { Logger } from '../../../utils/Logger'

class ParserRegistry {

  private static instance: ParserRegistry | undefined

  static getInstance(): ParserRegistry {
    if (ParserRegistry.instance === undefined) {
      ParserRegistry.instance = new ParserRegistry()
    }
    return ParserRegistry.instance
  }

  private readonly parsers = new Map<string, Parser>()

  private constructor() {
    this.register(new VLESSParser())
  }

  private register(parser: Parser): void {
    this.parsers.set(parser.scheme, parser)
  }

  getParser(scheme: string): Parser | undefined {
    return this.parsers.get(scheme)
  }
}

export namespace parser {

  export function parseLink(link: url.URL): object {
    const scheme = link.protocol.replace(':', '').trim()
    const parser = ParserRegistry.getInstance().getParser(scheme)
    if (parser) {
      return parser.parse(link)
    } else {
      throw new Error(`不支持的链接: ${link.href}`)
    }
  }

  export function parseSubscription(base64EncodedText: string): Array<object> {
    try {
      const plainText = StrUtil.unit8ArrayToStr(Base64Util.decodeSync(base64EncodedText.trim()))
      const lines = plainText.replaceAll('\r\n', '\n').trim().split('\n')
      const proxies: Array<object> = []
      for (let i = 0; i < lines.length; i++) {
        try {
          const line = lines[i].trim()
          const proxy = parseLink(url.URL.parseURL(line))
          proxies.push(proxy)
        } catch (err) {
          Logger.error(`parser.parseSubscription.for-loop.catch: ${JSON.stringify(err)}`)
          continue
        }
      }
      return proxies
    } catch (err) {
      Logger.error(`parser.parseSubscription.catch: ${JSON.stringify(err)}`)
      return []
    }
  }
}