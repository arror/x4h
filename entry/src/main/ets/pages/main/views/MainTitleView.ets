import { Nav } from "../../../utils/Nav"
import { VpnConnector, VpnStatus } from "../../../manager/vpn/VpnConnector"
import { SubscriptionManager } from "../../../manager/subscription/SubscriptionManager"
import { MainPageViewModel } from "../MainPageViewModel"

@ComponentV2
export struct MainTitleView {

  @Require @Param @Once vm: MainPageViewModel

  private readonly manager = SubscriptionManager.getInstance()
  private readonly connector = VpnConnector.getInstance()

  @Computed private get buttonTitle(): string {
    switch (this.connector.status) {
      case VpnStatus.Disconnected:
        return '启动'
      case VpnStatus.Connecting:
        return '连接中'
      case VpnStatus.Connected:
        return '断开'
      case VpnStatus.Disconnecting:
        return '断开中'
    }
  }

  @Computed private get buttonBackgroundColor(): ResourceColor {
    switch (this.connector.status) {
      case VpnStatus.Disconnected:
        return $r('sys.color.background_emphasize')
      case VpnStatus.Connecting:
        return $r('sys.color.background_emphasize')
      case VpnStatus.Connected:
        return Color.Green
      case VpnStatus.Disconnecting:
        return Color.Green
    }
  }

  build() {
    Row() {
      Text() {
        Span(this.manager.current.name)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
        Span(' ')
        SymbolSpan($r('sys.symbol.chevron_right'))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor([$r('sys.color.font_primary')])
      }
      .maxLines(1)
      .ellipsisMode(EllipsisMode.CENTER)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .padding({ left: 12, right: 12 })
      .size({ height: 32 })
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(100)
      .borderWidth(1)
      .borderColor($r('sys.color.font_tertiary'))
      .onClick(() => this.vm.switchToTab(Nav.MAIN_TAB_SUBSCRIPTION_LIST_PAGE_NAME))
      Row({ space: 12 }) {
        Button() {
          Text(this.buttonTitle)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.white'))
            .size({ width: '100%' })
            .textAlign(TextAlign.Center)
        }
        .backgroundColor(this.buttonBackgroundColor)
        .size({ width: 80, height: 32 })
        .onClick(() => this.onButtonClick())
        Button() {
          SymbolGlyph($r('sys.symbol.gearshape'))
            .fontColor([$r('sys.color.font_primary')])
            .fontWeight(FontWeight.Medium)
        }
        .size({ width: 32, height: 32 })
        .backgroundColor(Color.Transparent)
        .borderWidth(1)
        .borderColor($r('sys.color.font_tertiary'))
        .onClick(() => Nav.stack.pushPathByName(Nav.SETTINGS_VPN_PAGE_NAME, Object))
      }
    }
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
    .size({ width: '100%', height: '100%' })
  }

  private onButtonClick() {
    if (this.connector.status === VpnStatus.Disconnected) {
      this.connector.connect()
    } else if (this.connector.status === VpnStatus.Connected) {
      this.connector.disconnect()
    } else {
      return
    }
  }
}