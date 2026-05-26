import { AppUtil, FileUtil } from "@pura/harmony-utils"
import { Want } from "@kit.AbilityKit"
import { Logger } from "../../utils/Logger"
import { JSON } from "@kit.ArkTS"
import { VpnConfigManager } from "./VpnConfigManager"
import { SubscriptionManager } from "../subscription/SubscriptionManager"
import { fileIo } from "@kit.CoreFileKit"
import { vpnExtension } from "@kit.NetworkKit"
import { CoreConfigGenerator } from "../core/CoreConfigGenerator"
import { BrandLoading } from "../../utils/BrandLoading"
import { StatisticManager } from "./StatisticManager"

export enum VpnStatus {
  Disconnected = 0,
  Connecting = 1,
  Connected = 2,
  Disconnecting = 3
}


@ObservedV2
class VpnLoadingManager {

  private loading = new BrandLoading(AppUtil.getUIContext())

  @Trace counter: number = 0

  @Computed private get open(): boolean { return this.counter > 0 }

  @Monitor('open')
  onShowChanged() {
    if (this.open) {
      this.loading.open()
    } else {
      this.loading.close()
    }
  }
}

@ObservedV2
export class VpnConnector {

  private loading = new VpnLoadingManager()

  private static _instance: VpnConnector | undefined

  public static getInstance(): VpnConnector {
    if (VpnConnector._instance === undefined) {
      VpnConnector._instance = new VpnConnector()
    }
    return VpnConnector._instance
  }

  private readonly want: Want = { bundleName: AppUtil.getBundleName(), abilityName: 'VpnAbility' }

  private serviceId: number | undefined = undefined

  @Trace status = VpnStatus.Disconnected

  @Monitor('status')
  onStatusChanged() {
    switch (this.status) {
      case VpnStatus.Disconnected:
        this.loading.counter = Math.max(0, --this.loading.counter)
        if (this.loading.counter !== 0) {
          this.connect()
        }
        break
      case VpnStatus.Connecting:
        break
      case VpnStatus.Connected:
        this.loading.counter = Math.max(0, --this.loading.counter)
        break
      case VpnStatus.Disconnecting:
        break
    }
    if (this.status === VpnStatus.Connected) {
      StatisticManager.getInstance().start()
    } else {
      StatisticManager.getInstance().stop()
    }
  }

  reconnectIfNeeded(): void {
    if (this.status === VpnStatus.Connected) {
      this.loading.counter = 2
      this.disconnectServiceExtensionAbility()
    }
  }

  disconnectIfNeeded(): void {
    if (this.status === VpnStatus.Connected) {
      this.disconnect()
    }
  }

  connect(): void {
    try {
      this.generateCoreConfigFile()
    } catch (err) {
      Logger.error(`buildConfigFile.catch: ${JSON.stringify(err)}`)
      return
    }
    this.loading.counter = 1
    this.startVpnExtensionAbility()
  }

  disconnect(): void {
    this.loading.counter = 1
    this.disconnectServiceExtensionAbility()
  }

  private startVpnExtensionAbility(): void {
    Logger.debug(`VpnConnector.startVpnExtensionAbility`)
    this.status = VpnStatus.Connecting
    vpnExtension.startVpnExtensionAbility(this.want).then(() => {
      this.connectServiceExtensionAbility()
    }).catch((err: Error) => {
      Logger.debug(`VpnConnector.startVpnExtensionAbility.catch: ${JSON.stringify(err)}`)
      this.status = VpnStatus.Disconnected
    })
  }

  private stopVpnExtensionAbility(): void {
    Logger.debug(`VpnConnector.stopVpnExtensionAbility`)
    vpnExtension.stopVpnExtensionAbility(this.want).then().catch().finally(() => {
      setTimeout(() => this.status = VpnStatus.Disconnected, 250)
    })
  }

  private connectServiceExtensionAbility(): void {
    try {
      Logger.debug(`VpnConnector.connectServiceExtensionAbility`)
      const parameters: Record<string, Object> = {
        "VPN_CONFIG": VpnConfigManager.getInstance().buildRawConfig(),
        "ASSET_LOCATION": AppUtil.getContext().resourceDir,
        "CONFIG_LOCATION": FileUtil.getFilesDirPath('config', 'config.json')
      }
      this.serviceId = AppUtil.getContext().connectServiceExtensionAbility(
        { bundleName: this.want.bundleName, abilityName: this.want.abilityName, parameters: parameters },
        {
          onConnect: () => {
            Logger.debug(`VpnConnector.onConnect`)
            this.status = VpnStatus.Connected
          },
          onDisconnect: () => {
            Logger.debug(`VpnConnector.onDisconnect`)
            this.stopVpnExtensionAbility()
          },
          onFailed: () => {
            Logger.debug(`VpnConnector.onFailed`)
            this.stopVpnExtensionAbility()
          }
        })
      Logger.debug(`VpnConnector.connectServiceExtensionAbility.done`)
    } catch (err) {
      Logger.debug(`VpnConnector.connectServiceExtensionAbility.catch: ${JSON.stringify(err)}`)
      this.stopVpnExtensionAbility()
    }
  }

  private disconnectServiceExtensionAbility(): void {
    Logger.debug(`VpnConnector.disconnectServiceExtensionAbility`)
    this.status = VpnStatus.Disconnecting
    AppUtil.getContext().disconnectServiceExtensionAbility(this.serviceId).then(() => {
      Logger.debug(`VpnConnector.disconnectServiceExtensionAbility.then`)
    }).catch((err: Error) => {
      Logger.debug(`VpnConnector.disconnectServiceExtensionAbility.catch: ${JSON.stringify(err)}`)
    }).finally(() => this.serviceId = 0)
  }

  private generateCoreConfigFile(): void {
    let file: fileIo.File | undefined
    try {
      const config = CoreConfigGenerator.getInstance().generate(SubscriptionManager.getInstance().current)
      Logger.debug(config)
      const fp = FileUtil.getFilesDirPath('config', 'config.json')
      if (FileUtil.accessSync(fp)) {
        FileUtil.unlinkSync(fp)
      }
      file = FileUtil.openSync(fp, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
      FileUtil.writeSync(file.fd, config)
    } catch (err) {
      throw err as Error
    } finally {
      if (file) { FileUtil.close(file.fd) }
    }
  }
}