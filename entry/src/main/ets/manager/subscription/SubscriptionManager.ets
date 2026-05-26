import { PersistenceV2, Type } from "@ohos.arkui.StateManagement";
import { JSON, util } from "@kit.ArkTS";
import { FileUtil } from "@pura/harmony-utils";
import { Logger } from "../../utils/Logger";
import { FormatDate } from "../../utils/Date";
import { rcp } from "@kit.RemoteCommunicationKit";
import { parser } from "./parser/Parser";
import { VpnConnector } from "../vpn/VpnConnector";

@ObservedV2
export class SubscriptionObject {
  @Trace id: string = ''
  @Trace name: string = ''
  @Trace link: string = ''
  @Trace timestamp: string = ''
  @Trace count: number = 0
  @Trace selected: Array<string> = []

  static create(): SubscriptionObject {
    const obj = new SubscriptionObject()
    obj.id = util.generateRandomUUID()
    return obj
  }

  static default(): SubscriptionObject {
    const obj = new SubscriptionObject()
    obj.name = '默认'
    return obj
  }
}

@ObservedV2
export class SubscriptionDownloader {

  @Trace readonly ids = new Set<string>([])

  private static instance: SubscriptionDownloader | undefined

  private readonly session: rcp.Session

  private constructor() {
    try {
      this.session = rcp.createSession()
    } catch (err) {
      throw err as Error
    }
  }

  static getInstance(): SubscriptionDownloader {
    if (SubscriptionDownloader.instance === undefined) {
      SubscriptionDownloader.instance = new SubscriptionDownloader()
    }
    return SubscriptionDownloader.instance
  }

  async download(subscription: SubscriptionObject): Promise<Array<string>> {
    this.ids.add(subscription.id)
    try {
      const resp = await this.session.get(subscription.link)
      const text = resp.toString()
      if (text && typeof text === 'string') {
        const proxies = parser.parseSubscription(text)
        if (proxies.length === 0) {
          throw new Error('无可用节点')
        }
        const fp = FileUtil.getFilesDirPath('configs', `${subscription.id}.json`)
        if (await FileUtil.access(fp)) {
          await FileUtil.unlink(fp)
        }
        interface Config { outbounds: Array<object> }
        await FileUtil.writeEasy(fp, JSON.stringify({ outbounds: proxies } as Config))
        return proxies.map((p) => p['tag'] as string)
      } else {
        throw new Error('订阅加载错误')
      }
    } catch (err) {
      Logger.error(`SubscriptionDownloader.createOrUpdate error: ${JSON.stringify(err)}`)
      throw err as Error
    } finally {
      this.ids.delete(subscription.id)
    }
  }
}

@ObservedV2
export class SubscriptionManager {

  @Trace @Type(SubscriptionObject) current: SubscriptionObject = SubscriptionObject.default()
  @Trace @Type(SubscriptionObject) subscriptions: Array<SubscriptionObject> = []

  private static instance: SubscriptionManager | undefined
  private static storeKey: string = 'SUBSCRIPTION_MANAGER_V1'

  static getInstance(): SubscriptionManager {
    if (SubscriptionManager.instance === undefined) {
      SubscriptionManager.instance = PersistenceV2.globalConnect({
        type: SubscriptionManager,
        key: SubscriptionManager.storeKey,
        defaultCreator: () => new SubscriptionManager()
      })!
    }
    return SubscriptionManager.instance
  }

  async createOrUpdate(subscription: SubscriptionObject): Promise<void> {
    try {
      const names = await SubscriptionDownloader.getInstance().download(subscription)
      const find = this.subscriptions.findIndex((s) => s.id === subscription.id)
      if (find < 0) {
        subscription.selected = names
        this.subscriptions.unshift(subscription)
      } else {
        const set = new Set(names)
        subscription.selected = subscription.selected.filter((n) => set.has(n))
        if (subscription.selected.length === 0) {
          subscription.selected = names
        }
      }
      subscription.count = names.length
      subscription.timestamp = FormatDate(Date())
      if (this.current.id === '' || this.current.id === subscription.id) {
        this.setCurrent(subscription)
      }
      this.save()
    } catch (e) {
      Logger.error(`createOrUpdate error: ${JSON.stringify(e)}`)
      throw e as Error
    }
  }

  delete(subscription: SubscriptionObject): void {
    this.subscriptions.splice(this.subscriptions.indexOf(subscription), 1)
    if (this.current.id === subscription.id) {
      this.current = this.subscriptions[0] ?? SubscriptionObject.default()
      VpnConnector.getInstance().disconnectIfNeeded()
    }
    this.save()
  }

  setCurrent(current: SubscriptionObject): void {
    this.current = current
    VpnConnector.getInstance().reconnectIfNeeded()
    this.save()
  }

  save(): void {
    PersistenceV2.save(SubscriptionManager.storeKey)
  }
}