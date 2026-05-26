import { commonEventManager } from "@kit.BasicServicesKit"

export interface Statistic {
  totalUp: number
  totalDown: number
  speedUp: number
  speedDown: number
}

@ObservedV2
export class StatisticManager {

  @Trace statistic: Statistic = { totalUp: 0, totalDown: 0, speedUp: 0, speedDown: 0 }

  @Trace private subscriber: commonEventManager.CommonEventSubscriber | undefined

  @Computed get on(): boolean {
    return this.subscriber !== undefined
  }

  private static _instance: StatisticManager | undefined

  public static getInstance(): StatisticManager {
    if (StatisticManager._instance === undefined) {
      StatisticManager._instance = new StatisticManager()
    }
    return StatisticManager._instance
  }

  start(): void {
    if (this.subscriber === undefined) {
      this.subscriber = commonEventManager.createSubscriberSync({ events: ['VPN_TRAFFIC'] })
    }
    commonEventManager.subscribeToEvent(this.subscriber, (data) => {
      this.statistic = {
        totalUp: data.parameters!['TOTAL_UP'] as number,
        totalDown: data.parameters!['TOTAL_DOWN'] as number,
        speedUp: data.parameters!['SPEED_UP'] as number,
        speedDown: data.parameters!['SPEED_DOWN'] as number
      }
    }).catch()
  }

  stop(): void {
    if (this.subscriber) {
      commonEventManager.unsubscribe(this.subscriber)
    }
    this.subscriber = undefined
  }
}