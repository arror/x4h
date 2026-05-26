import { statistics, vpnExtension, VpnExtensionAbility } from '@kit.NetworkKit';
import { rpc } from '@kit.IPCKit';
import { JSON, process } from '@kit.ArkTS';
import { Logger } from '../utils/Logger';
import { Want } from '@kit.AbilityKit';
import { Core } from '../lib/Core';
import { commonEventManager } from '@kit.BasicServicesKit';
import { AppUtil } from '@pura/harmony-utils';

interface Statistic {
  totalUp: number
  totalDown: number
  speedUp: number
  speedDown: number
}

export default class VpnAbility extends VpnExtensionAbility {

  private connection = new Object as vpnExtension.VpnConnection

  onCreate(): void {
    Logger.debug(`VpnAbility.onCreate`)
    this.connection = vpnExtension.createVpnConnection(this.context)
  }

  async onConnect(want: Want): Promise<rpc.RemoteObject> {
    try {
      Logger.debug(`VpnAbility.onConnect`)
      const fd = await this.connection.create(want.parameters!['VPN_CONFIG'] as vpnExtension.VpnConfig)
      Core.run({
        fd: fd,
        assetLocation: want.parameters!['ASSET_LOCATION'] as string,
        configLocation: want.parameters!['CONFIG_LOCATION'] as string
      })
      this.startStatisticLoop()
      return new rpc.RemoteObject('XRAY_CORE_VPN_ABILITY')
    } catch (err) {
      Logger.error(`VpnAbility.onConnect catch: ${JSON.stringify(err)}`)
      throw err as Error
    }
  }

  async onDisconnected(): Promise<void> {
    try {
      await this.connection.destroy()
    } catch (err) {
      Logger.debug(`VpnAbility.onDisconnected catch: ${JSON.stringify(err)}`)
    } finally {
      this.connection = new Object as vpnExtension.VpnConnection
    }
  }

  onDestroy(): void {
    Logger.debug(`VpnAbility.onDestroy`)
    const pm = new process.ProcessManager()
    pm.exit(0)
  }

  private readonly statistic: Statistic = { totalUp: 0, totalDown: 0, speedUp: 0, speedDown: 0 }

  private startStatisticLoop(): void {
    const timer = setInterval(() => {
      this.fetch().then(() => {
        commonEventManager.publish('VPN_TRAFFIC', {
          bundleName: AppUtil.getBundleName(),
          parameters: {
            'TOTAL_UP': this.statistic.totalUp,
            'TOTAL_DOWN': this.statistic.totalDown,
            'SPEED_UP': this.statistic.speedUp,
            'SPEED_DOWN': this.statistic.speedDown,
          }
        }, () => {})
      }).catch(() => {
        clearInterval(timer)
      })
    }, 1000)
  }

  private async fetch(): Promise<void> {
    try {
      const totalUp = await statistics.getIfaceTxBytes('vpn-tun')
      const totalDown = await statistics.getIfaceRxBytes('vpn-tun')
      this.statistic.speedUp = totalUp - this.statistic.totalUp
      this.statistic.speedDown = totalDown - this.statistic.totalDown
      this.statistic.totalUp = totalUp
      this.statistic.totalDown = totalDown
    } catch (err) {
      Logger.error(JSON.stringify(err))
      throw err as Error
    }
  }
}

