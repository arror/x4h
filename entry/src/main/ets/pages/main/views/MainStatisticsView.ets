import { StatisticManager } from "../../../manager/vpn/StatisticManager";

@ComponentV2
export struct MainStatisticsView {

  private readonly manager = StatisticManager.getInstance()

  build() {
    Column({ space: 24 }) {
      Column({ space: 8 }) {
        Text('数据统计')
          .size({ width: '100%' })
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
        Text('统计的数据为流经虚拟网卡的上下行流量')
          .size({ width: '100%' })
          .fontSize(12)
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.font_tertiary'))
      }
      .size({ width: '100%' })
      Row() {
        TrafficView({
          on: this.manager.on,
          trafficDirection: TrafficDirection.UP,
          icon: $r('sys.symbol.arrow_up_circle'),
          total: this.manager.statistic.totalUp,
          speed: this.manager.statistic.speedUp
        }).layoutWeight(1)
        TrafficView({
          on: this.manager.on,
          trafficDirection: TrafficDirection.DOWN,
          icon: $r('sys.symbol.arrow_down_circle'),
          total: this.manager.statistic.totalDown,
          speed: this.manager.statistic.speedDown
        }).layoutWeight(1)
      }
      .size({ width: '100%' })
    }
    .size({ width: '100%' })
    .padding(12)
    .borderRadius(12)
    .backgroundColor($r('sys.color.comp_background_primary'))
  }
}

enum TrafficDirection {
  UP = 0,
  DOWN = 1
}

@ComponentV2
struct TrafficView {

  @Require @Param on: boolean
  @Require @Param trafficDirection: TrafficDirection
  @Require @Param icon: Resource
  @Require @Param total: number
  @Require @Param speed: number

  @Computed get totalDisplayString(): string {
    const info = this.format(this.total, '')
    if (info[1].length === 0) {
      return info[0]
    } else {
      return `${info[0]} ${info[1]}`
    }
  }

  @Computed get speedDisplayString(): string {
    const info = this.format(this.speed, '/s')
    if (info[1].length === 0) {
      return info[0]
    } else {
      return `${info[0]} ${info[1]}`
    }
  }

  build() {
    Column({ space: 8 }) {
      SymbolGlyph(this.icon)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor([this.trafficDirection === TrafficDirection.UP ? $r('sys.color.background_emphasize') : $r('sys.color.confirm')])
      Text(this.speedDisplayString)
        .fontSize(14)
        .fontColor($r('sys.color.font_primary'))
        .size({ width: '100%' })
        .textAlign(TextAlign.Center)
      Text(this.totalDisplayString)
        .fontSize(12)
        .fontColor($r('sys.color.font_tertiary'))
        .size({ width: '100%' })
        .textAlign(TextAlign.Center)
    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .size({ width: '100%' })
  }

  private format(bytes: number, suffix: string): [string, string] {
    if (!this.on) {
      return ['--', '']
    }
    if (bytes === 0) {
      return ['0', 'B'+suffix]
    }
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    const value = bytes / Math.pow(k, i)
    return [`${parseFloat(value.toFixed(2))}`, `${sizes[i]}` + suffix]
  }
}