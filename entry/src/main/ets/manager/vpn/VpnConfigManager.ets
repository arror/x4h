import { PersistenceV2 } from "@kit.ArkUI"
import { vpnExtension } from "@kit.NetworkKit"
import { AppUtil } from "@pura/harmony-utils"

@ObservedV2
export class VpnConfigManager {

  static readonly ipv4Address: vpnExtension.LinkAddress = { address: { address: '172.16.0.1', family: 1 }, prefixLength: 24 }
  static readonly ipv6Address: vpnExtension.LinkAddress = { address: { address: 'fd00::1',    family: 2 }, prefixLength: 64 }

  static readonly ipv4Route: vpnExtension.RouteInfo = {
    interface: 'vpn-tun',
    destination: { address: { address: '0.0.0.0', family: 1 }, prefixLength: 0 },
    gateway: { address: '' },
    hasGateway: false,
    isDefaultRoute: false
  }
  static readonly ipv6Route: vpnExtension.RouteInfo = {
    interface: 'vpn-tun',
    destination: { address: { address: '::',      family: 2 }, prefixLength: 0 },
    gateway: { address: '' },
    hasGateway: false,
    isDefaultRoute: false
  }

  @Trace isIPv4Accepted: boolean = true
  @Trace isIPv6Accepted: boolean = false
  @Trace mtu: number = 1500
  @Trace dnsAddresses: Array<string> = []
  @Trace searchDomains: Array<string> = []
  @Trace excludedRoutes: Array<string> = []
  @Trace trustedApplications: Array<string> = []
  @Trace blockedApplications: Array<string> = []
  @Trace isTrustedApplicationsEnable: boolean = false
  @Trace isBlockedApplicationsEnable: boolean = false

  private static instance: VpnConfigManager | undefined
  private static storeKey: string = 'VPN_CONFIG_MANAGER_V1'

  public static getInstance(): VpnConfigManager {
    if (VpnConfigManager.instance === undefined) {
      VpnConfigManager.instance = PersistenceV2.globalConnect({
        type: VpnConfigManager,
        key: VpnConfigManager.storeKey,
        defaultCreator: () => new VpnConfigManager()
      })!
    }
    return VpnConfigManager.instance
  }

  public buildRawConfig(): vpnExtension.VpnConfig {
    const config: vpnExtension.VpnConfig = {
      addresses: [VpnConfigManager.ipv4Address, VpnConfigManager.ipv6Address],
      mtu: this.mtu,
      dnsAddresses: this.dnsAddresses.length === 0 ? undefined : this.dnsAddresses,
      searchDomains: this.searchDomains.length === 0 ? undefined : this.searchDomains,
      isIPv4Accepted: this.isIPv4Accepted,
      isIPv6Accepted: this.isIPv6Accepted
    }
    const routes: Array<vpnExtension.RouteInfo> = []
    routes.push(...this.excludedRoutes.map(value => {
      const temp = value.split('/')
      const prefixLength = parseInt(temp[1], 10)
      const route: vpnExtension.RouteInfo = {
        interface: 'vpn-tun',
        destination: {
          address: { address: temp[0], family: temp[0].includes('.') ? 1 : 2 },
          prefixLength: prefixLength
        },
        gateway: { address: '' },
        hasGateway: false,
        isDefaultRoute: false,
        isExcludedRoute: true
      }
      return route
    }))
    routes.push(VpnConfigManager.ipv4Route, VpnConfigManager.ipv6Route)
    config.routes = routes
    if (this.isTrustedApplicationsEnable) {
      config.trustedApplications = this.trustedApplications.length === 0 ? undefined : this.trustedApplications
    } else if (this.isBlockedApplicationsEnable) {
      config.blockedApplications = [AppUtil.getBundleName()].concat(...this.blockedApplications)
    } else {
      config.blockedApplications = [AppUtil.getBundleName()]
    }
    return config
  }
}