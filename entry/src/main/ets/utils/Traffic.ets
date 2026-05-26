import { statistics } from "@kit.NetworkKit"
import { FileUtil, NumberUtil } from "@pura/harmony-utils"

@ObservedV2
export class Traffic {

  @Trace up: string = '--'
  @Trace down: string = '--'
  @Trace private timer: number | undefined = undefined

  private constructor() {}

  private static _instance: Traffic | undefined

  static getInstance(): Traffic {
    if (Traffic._instance === undefined) {
      Traffic._instance = new Traffic()
    }
    return Traffic._instance
  }

  start(): void {
    this.getTraffic()
    this.timer = setInterval(() => this.getTraffic(), 1000)
  }

  stop(): void {
    this.up = '--'
    this.down = '--'
    clearInterval(this.timer)
  }

  private getTraffic(): void {
    statistics.getIfaceTxBytes('vpn-tun').then((value) => this.up = this.formatFileSize(value)).catch()
    statistics.getIfaceRxBytes('vpn-tun').then((value) => this.down = this.formatFileSize(value)).catch()
  }

  formatFileSize(bytes: number, decimals: number = 2): string {
    if (bytes === 0) {
      return '0 B'
    }
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB']
    const i = Math.floor(Math.log(bytes) / Math.log(FileUtil.KB))
    if (decimals < 0) {
      let formatSize = Math.trunc(bytes / Math.pow(FileUtil.KB, i))
      return `${formatSize} ${sizes[i]}`
    } else {
      let formatSize = NumberUtil.keepDecimals(bytes / Math.pow(FileUtil.KB, i), decimals)
      return `${formatSize} ${sizes[i]}`
    }
  }
}