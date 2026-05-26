import { FileUtil } from '@pura/harmony-utils'
import { SubscriptionManager } from '../../../manager/subscription/SubscriptionManager'
import { JSON, util } from '@kit.ArkTS'
import { Logger } from '../../../utils/Logger'
import { commonEventManager } from '@kit.BasicServicesKit'
import { NavigationIndicatorHeightObserver } from '../../../utils/NavigationIndicatorHeightObserver'
import { Ping } from '../../../lib/Ping'

@ObservedV2
class Outbound {

  readonly name: string
  readonly type: string

  @Trace delay: number = 0
  @Trace selected: boolean = false

  constructor(name: string, type: string) {
    this.name = name
    this.type = type
  }
}

@ObservedV2
class MainOutboundSheetViewModel {

  private readonly session = util.generateRandomUUID()

  private readonly path: string
  private readonly manager = SubscriptionManager.getInstance()
  private readonly subscriber = commonEventManager.createSubscriberSync({ events: [this.session] })

  readonly group = this.manager.current.id

  @Trace isMeasuring: boolean = false

  @Trace outbounds: Array<Outbound> = []

  @Trace selected: Array<string> = []

  private mapping: Map<string, Outbound> = new Map()

  constructor() {
    this.path = FileUtil.getFilesDirPath('configs', `${this.manager.current.id}.json`)
    const text = FileUtil.readTextSync(this.path)
    interface OutboundInterface {
      tag: string
      protocol: string
    }
    interface ConfigInterface {
      outbounds: Array<OutboundInterface>
    }
    Logger.debug(text)
    const config = JSON.parse(text) as ConfigInterface
    this.outbounds = config.outbounds.map((o) => new Outbound(o.tag, o.protocol))
    this.mapping = this.outbounds.reduce((m, o) => {
      m.set(o.name, o)
      return m
    }, new Map<string, Outbound>())
    this.selected = this.manager.current.selected
    this.selected.forEach((name) => {
      const outbound = this.mapping.get(name)
      if (outbound) {
        outbound.selected = true
      }
    })
  }

  aboutToAppear(): void {
    commonEventManager.subscribeToEvent(this.subscriber, (data) => {
      const name = data.data || ''
      switch (name) {
        case 'START':
          this.isMeasuring = true
          break
        case 'END':
          this.isMeasuring = false
          Ping.stop(this.session)
          break
        default:
          const name = data.parameters!['outbound'] as string
          const delay = data.parameters!['delay'] as number
          if (typeof name === 'string' && typeof delay === 'number') {
            const outbound = this.mapping.get(name)
            if (outbound) {
              outbound.delay = delay
            }
          }
          break
      }
    }).catch()
    this.ping()
  }

  aboutToDisappear(): void {
    commonEventManager.unsubscribe(this.subscriber)
    Ping.stop(this.session)
  }

  ping(): void {
    this.outbounds.forEach((o) => o.delay = 0)
    Ping.start(this.session, this.path)
  }
}

@ComponentV2
export struct MainOutboundSheetView {

  @Require @Param @Once onConfirm: (_:Array<string>) => void
  @Require @Param @Once onClose: () => void

  private readonly indicatorHeightObserver = NavigationIndicatorHeightObserver.getInstance()

  private readonly vm = new MainOutboundSheetViewModel()

  aboutToAppear() {
    this.vm.aboutToAppear()
  }

  aboutToDisappear(): void {
    this.vm.aboutToDisappear()
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        Column({ space: 8 }) {
          Text('出站')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
          Text('支持选择多个节点')
            .fontSize(12)
            .fontWeight(FontWeight.Regular)
            .fontColor($r('sys.color.font_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
        Blank()
        Button() {
          if (this.vm.isMeasuring) {
            LoadingProgress()
              .size({ width: 20, height: 20 })
          } else {
            SymbolGlyph($r('sys.symbol.timer'))
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor([$r('sys.color.font_primary')])
          }
        }
        .buttonStyle(ButtonStyleMode.NORMAL)
        .size({ width: 32, height: 32 })
        .hitTestBehavior(this.vm.isMeasuring ? HitTestMode.None : HitTestMode.Default)
        .onClick(() => this.vm.ping())
        Button() {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor([$r('sys.color.font_primary')])
        }
        .buttonStyle(ButtonStyleMode.NORMAL)
        .size({ width: 32, height: 32 })
        .onClick(() => this.onClose())
      }
      .size({ width: '100%' })
      .padding(16)
      Divider()
      Column() {
        List() {
          ListItemGroup() {
            ForEach(this.vm.outbounds, (outbound: Outbound) => {
              ListItem() {
                OutboundView({ group: this.vm.group, outbound: outbound })
              }
            })
          }
          .divider({ strokeWidth: '1px', color: $r('sys.color.comp_divider') })
          .size({ width: '100%' })
          .padding({ left: 16, right: 16 })
          .borderRadius(12)
        }
        .width('100%')
        .height('100%')
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      }
      .layoutWeight(1)
      Divider()
      Row({ space: 8 }) {
        Row({ space: 8 }) {
          CheckboxGroup({ group: this.vm.group })
            .margin(0)
            .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
            .size({ width: 16, height: 16 })
            .hitTestBehavior(HitTestMode.None)
            .onChange((v) => this.vm.selected = v.name)
          Column({ space: 4 }) {
            Text(`已选择: ${this.vm.selected.length}/${this.vm.outbounds.length}`)
              .fontSize(12)
              .fontColor($r('sys.color.font_primary'))
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .fontWeight(FontWeight.Medium)
              .ellipsisMode(EllipsisMode.END)
              .maxLines(1)
            Text('选择多个节点时, 核心将根据连接观测结果选择延迟最小的节点作为出站代理')
              .fontSize(10)
              .fontColor($r('sys.color.font_secondary'))
              .fontWeight(FontWeight.Regular)
              .ellipsisMode(EllipsisMode.END)
              .maxLines(2)
              .visibility(Visibility.None)
          }
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1)
        }
        .layoutWeight(1)
        .onClick(() => this.vm.outbounds.forEach((o) => o.selected = this.vm.selected.length < this.vm.outbounds.length))
        Button('确定')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .size({ width: 76, height: 32 })
          .enabled(this.vm.selected.length > 0)
          .onClick(() => this.onConfirm(this.vm.selected))
      }
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween)
      .size({ width: '100%' })
      .padding({ left: 16, right: 16, top: 16, bottom: Math.max(this.indicatorHeightObserver.height, 16) })
    }
    .size({ width: '100%', height: '100%' })
  }
}

@ComponentV2
struct OutboundView {

  @Require @Param group: string
  @Require @Param outbound: Outbound

  @Computed private get delayString(): string {
    const delay = this.outbound.delay
    if (delay === 0) {
      return '...'
    } else if (delay > 9999) {
      return '超时'
    } else {
      return delay + 'ms'
    }
  }

  @Computed private get delayColor(): ResourceColor {
    const delay = this.outbound.delay
    if (delay === 0) {
      return $r('sys.color.font_secondary')
    } else if (delay > 9999) {
      return $r('sys.color.warning')
    } else {
      return $r('sys.color.confirm')
    }
  }

  build() {
    Row({ space: 8 }) {
      Checkbox({ group: this.group, name: this.outbound.name })
        .margin(0)
        .shape(CheckBoxShape.ROUNDED_SQUARE)
        .select(this.outbound.selected!!)
        .size({ width: 16, height: 16 })
        .hitTestBehavior(HitTestMode.None)
      Column({ space: 4 }) {
        Text(this.outbound.name)
          .fontSize(12)
          .fontColor($r('sys.color.font_primary'))
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontWeight(FontWeight.Medium)
          .ellipsisMode(EllipsisMode.END)
          .maxLines(1)
          .alignSelf(ItemAlign.Stretch)
        Text(this.outbound.type)
          .fontSize(10)
          .fontColor($r('sys.color.font_secondary'))
          .alignSelf(ItemAlign.Stretch)
      }
      .layoutWeight(1)
      Text(this.delayString)
        .fontSize(10)
        .fontColor(this.delayColor)
    }
    .padding({ top: 8, bottom: 8 })
    .onClick(() => this.outbound.selected = !this.outbound.selected)
  }
}