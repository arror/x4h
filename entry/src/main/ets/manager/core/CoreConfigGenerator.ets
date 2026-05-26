import { FileUtil } from "@pura/harmony-utils";
import { SubscriptionObject } from "../subscription/SubscriptionManager";
import { JSON } from "@kit.ArkTS";
import { CoreConfigManager, CoreOutboundStrategy } from "./CoreConfigManager";
import { VpnConfigManager } from "../vpn/VpnConfigManager";

interface InboundSettings {
  name: string
  MTU: number
}

interface Sniffing {
  enabled: boolean
  destOverride: Array<string>
  routeOnly: boolean
}

interface Inbound {
  tag: string
  protocol: string
  settings: InboundSettings
  sniffing: Sniffing
}

interface BalancerStrategy {
  type: 'random' | 'roundRobin' | 'leastPing'
}

interface Balancer {
  tag: string
  selector: Array<string>
  fallbackTag: string
  strategy: BalancerStrategy
}

interface Outbound {
  tag: string
  protocol: string
}

export class CoreConfigGenerator {

  private readonly direct: Outbound = {
    tag: 'direct',
    protocol: 'freedom'
  }

  private readonly reject: Outbound = {
    tag: 'reject',
    protocol: 'blackhole'
  }

  private static instance: CoreConfigGenerator | undefined

  static getInstance(): CoreConfigGenerator {
    if (CoreConfigGenerator.instance === undefined) {
      CoreConfigGenerator.instance = new CoreConfigGenerator()
    }
    return CoreConfigGenerator.instance
  }

  private generateOutbounds(subscription: SubscriptionObject): Array<Outbound> {
    interface Config {
      outbounds: Array<Outbound>
    }
    if (subscription.id === '') {
      return []
    } else {
      const text = FileUtil.readTextSync(FileUtil.getFilesDirPath('configs', `${subscription.id}.json`))
      const tags = new Set(subscription.selected)
      return (JSON.parse(text) as Config).outbounds.filter((o) => tags.has(o.tag))
    }
  }

  generate(subscription: SubscriptionObject): string {

    const manager = CoreConfigManager.getInstance()

    const outbounds = this.generateOutbounds(subscription)

    const config: Record<string, Object> = {}

    {
      config.log = manager.log.buildRawConfig() as Object
    } // 日志

    {
      const inbound: Inbound = {
        tag: 'tun',
        protocol: "tun",
        settings: {
          name: 'vpn-tun',
          MTU: VpnConfigManager.getInstance().mtu
        },
        sniffing: {
          enabled: true,
          destOverride: ['http', 'tls'],
          routeOnly: true
        }
      }
      config.inbounds = [inbound]
    } // 入站

    {
      if (outbounds.length !== 0) {
        config.stats = {} as Record<string, Object>
      }
    } // 统计

    {
      if (outbounds.length > 1) {
        const observatory: Record<string, Object> = {}
        observatory.subjectSelector = outbounds.map((o) => o.tag)
        observatory.probeUrl = 'https://www.google.com/generate_204'
        observatory.probeInterval = '60s'
        observatory.enableConcurrency = true
        config.observatory = observatory
      }
    } // 测量，负载均衡使用

    {
      const routing: Record<string, Object> = {}
      config.routing = routing

      if (outbounds.length > 1) {
        const balancer: Balancer = {
          tag: 'balancer',
          selector: outbounds.map((o) => o.tag),
          fallbackTag: 'direct',
          strategy: {
            type: 'leastPing'
          }
        }
        routing.balancers = [balancer]
      } // 负载均衡

      const rules: Array<object> = []
      routing.rules = rules
      {
        const rule: Record<string, Object> = {}
        rule.inboundTag = ['tun']
        rule.network = 'udp'
        rule.port = 443
        rule.outboundTag = 'reject'
        rules.push(rule)
      } // 阻断UDP443
      {
        const rule: Record<string, Object> = {}
        rule.inboundTag = ['tun']
        rule.domain = ['geosite:category-ads-all']
        rule.outboundTag = 'reject'
        rules.push(rule)
      } // 过滤广告
      {
        const rule: Record<string, Object> = {}
        rule.inboundTag = ['tun']
        rule.ip = ['geoip:private']
        rule.outboundTag = 'direct'
        rules.push(rule)
      } // 绕过局域网IP
      {
        const rule: Record<string, Object> = {}
        rule.inboundTag = ['tun']
        rule.domain = ['geosite:private']
        rule.outboundTag = 'direct'
        rules.push(rule)
      } // 绕过局域网域名
      if (manager.outbound.strategy === CoreOutboundStrategy.RULE) {
        {
          const rule: Record<string, Object> = {}
          rule.inboundTag = ['tun']
          rule.ip = [
            '223.5.5.5',
            '223.6.6.6',
            '2400:3200::1',
            '2400:3200:baba::1',
            '119.29.29.29',
            '1.12.12.12',
            '120.53.53.53',
            '2402:4e00::',
            '2402:4e00:1::',
            '180.76.76.76',
            '2400:da00::6666',
            '114.114.114.114',
            '114.114.115.115',
            '114.114.114.119',
            '114.114.115.119',
            '114.114.114.110',
            '114.114.115.110',
            '180.184.1.1',
            '180.184.2.2',
            '101.226.4.6',
            '218.30.118.6',
            '123.125.81.6',
            '140.207.198.6',
            '1.2.4.8',
            '210.2.4.8',
            '52.80.66.66',
            '117.50.22.22',
            '2400:7fc0:849e:200::4',
            '2404:c2c0:85d8:901::4',
            '117.50.10.10',
            '52.80.52.52',
            '2400:7fc0:849e:200::8',
            '2404:c2c0:85d8:901::8',
            '117.50.60.30',
            '52.80.60.30'
          ]
          rule.outboundTag = 'direct'
          rules.push(rule)
        } // 绕过中国公共 DNS IP
        {
          const rule: Record<string, Object> = {}
          rule.inboundTag = ['tun']
          rule.domain = [
            'domain:alidns.com',
            'domain:doh.pub',
            'domain:dot.pub',
            'domain:360.cn',
            'domain:onedns.net'
          ]
          rule.outboundTag = 'direct'
          rules.push(rule)
        } // 绕过中国公共 DNS 域名
        {
          const rule: Record<string, Object> = {}
          rule.inboundTag = ['tun']
          rule.ip = ['geoip:cn']
          rule.outboundTag = 'direct'
          rules.push(rule)
        } // 绕过中国IP
        {
          const rule: Record<string, Object> = {}
          rule.inboundTag = ['tun']
          rule.domain = ['geosite:cn']
          rule.outboundTag = 'direct'
          rules.push(rule)
        } // 绕过中国域名
      }
      {
        const rule: Record<string, Object> = {}
        rule.inboundTag = ['tun']
        if (outbounds.length === 0) { // 没有代理节点
          rule.outboundTag = 'direct'
        } else  if (outbounds.length === 1) { // 只有一个代理节点
          rule.outboundTag = outbounds[0].tag
        } else { // 有多个代理节点
          rule.balancerTag = 'balancer'
        }
        rules.push(rule)
      } // 默认策略
    } // 路由

    {
      config.outbounds = outbounds.concat(this.direct, this.reject)
    } // 出站

    return JSON.stringify(config)
  }
}