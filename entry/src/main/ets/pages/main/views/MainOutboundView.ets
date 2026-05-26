import {
  CapsuleSegmentButtonV2,
  LengthMetrics,
  SegmentButtonV2ItemOptions,
  SegmentButtonV2Items
} from "@kit.ArkUI"
import { VpnConnector } from "../../../manager/vpn/VpnConnector"
import { SubscriptionManager } from "../../../manager/subscription/SubscriptionManager"
import { MainOutboundSheetView } from "./MainOutboundSheetView"
import {
  CoreConfigManager,
  CoreOutboundStrategies,
  CoreOutboundStrategyNameOf
} from "../../../manager/core/CoreConfigManager"

@ComponentV2
export struct MainOutboundView {

  private readonly connector = VpnConnector.getInstance()
  private readonly manager = SubscriptionManager.getInstance()
  private readonly outbound = CoreConfigManager.getInstance().outbound

  @Local private isShow: boolean = false

  build() {
    Column({ space: 24 }) {
      Column({ space: 8 }) {
        Text('出站')
          .size({ width: '100%' })
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
        Text('选择多个节点时, 核心将根据连接观测结果选择延迟最小的节点作为出站代理')
          .size({ width: '100%' })
          .fontSize(12)
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.font_tertiary'))
      }
      .size({ width: '100%' })
      Row({ space: 12 }) {
        CapsuleSegmentButtonV2({
          items: new SegmentButtonV2Items(CoreOutboundStrategies.map((v) => {
            return {
              text: CoreOutboundStrategyNameOf(v)
            } as SegmentButtonV2ItemOptions
          })),
          selectedIndex: this.outbound.strategy,
          itemFontSize: LengthMetrics.vp(12),
          itemSelectedFontSize: LengthMetrics.vp(12),
          itemBorderRadius: LengthMetrics.vp(6),
          buttonBorderRadius: LengthMetrics.vp(8),
          itemMinHeight: LengthMetrics.vp(28),
          buttonMinHeight: LengthMetrics.vp(32),
          onItemClicked: (v) => {
            this.outbound.strategy = v
            this.connector.reconnectIfNeeded()
          },
        }).layoutWeight(1)
        Button(`节点: ${this.manager.current.selected.length}/${this.manager.current.count}`)
          .buttonStyle(ButtonStyleMode.NORMAL)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .borderRadius(8)
          .size({ height: 32 })
          .backgroundColor($r('sys.color.button_background_color_transparent'))
          .onClick(() => this.isShow = true)
      }
      .size({ width: '100%' })
    }
    .size({ width: '100%' })
    .padding(12)
    .borderRadius(12)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .bindSheet(this.isShow!!, this.buildSheet(), {
      height: SheetSize.FIT_CONTENT,
      showClose: false,
      showInSubWindow: false,
      radius: LengthMetrics.vp(16),
      backgroundColor: $r('sys.color.comp_background_primary')
    })
    .visibility(this.manager.current.id === '' ? Visibility.None : Visibility.Visible)
  }

  @Builder private buildSheet() {
    MainOutboundSheetView({
      onConfirm: (names) => {
        this.isShow = false
        const changed = !this.isEqual(this.manager.current.selected, names)
        this.manager.current.selected = names
        if (changed) { this.connector.reconnectIfNeeded() }
      },
      onClose: () => this.isShow = false
    })
  }

  private isEqual(lhs: Array<string>, rhs: Array<string>): boolean {
    if (lhs.length == rhs.length) {
      return lhs.sort().join(',') === rhs.sort().join(',')
    } else {
      return false
    }
  }
}

