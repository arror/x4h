import { Nav } from "../../utils/Nav"
import { MainPageViewModel } from "./MainPageViewModel"
import { SettingsLogPageBuilder } from "../settings/SettingsLogPage"
import { SettingsVpnPageBuilder } from "../settings/SettingsVpnPage"
import { SettingsVpnValueInputPageBuilder } from "../settings/SettingsVpnValueInputPage"
import { SubscriptionListPageBuilder } from "../subscribe/SubscriptionListPage"
import { SubscriptionEditingPageBuilder } from "../subscribe/SubscriptionEditingPage"
import { MainTitleView } from "./views/MainTitleView"
import { MainOutboundView } from "./views/MainOutboundView"
import { MainLogEntranceView } from "./views/MainLogEntranceView"
import { MainStatisticsView } from "./views/MainStatisticsView"

@Entry
@ComponentV2
struct MainPage {

  private readonly vm = new MainPageViewModel()

  build() {
    Navigation(Nav.stack) {
      Scroll() {
        Column({ space: 32 }) {
          MainOutboundView()
          MainStatisticsView()
          MainLogEntranceView()
        }
        .padding(16)
      }
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .size({ width: '100%', height: '100%' })
    }
    .titleMode(NavigationTitleMode.Mini)
    .navBarWidth(320)
    .hideBackButton(true)
    .title(this.buildTitle())
    .navDestination(this.navDestinationBuilder)
    .mode(NavigationMode.Auto)
    .onNavigationModeChange((mode) => this.vm.onNavigationModeChange(mode))
    .backgroundColor($r('sys.color.background_secondary'))
  }

  @Builder
  private buildTitle() {
    MainTitleView({ vm: this.vm })
  }

  @Builder
  private navDestinationBuilder(name: string, params: Object) {
    if (name === Nav.SETTINGS_LOG_PAGE_NAME) {
      SettingsLogPageBuilder(params)
    } else if (name === Nav.SETTINGS_VPN_PAGE_NAME) {
      SettingsVpnPageBuilder(params)
    } else if (name === Nav.SETTINGS_VPN_VALUE_INPUT_PAGE_NAME) {
      SettingsVpnValueInputPageBuilder(params)
    } else if (name === Nav.MAIN_TAB_SUBSCRIPTION_LIST_PAGE_NAME) {
      SubscriptionListPageBuilder(params)
    } else if (name === Nav.SUBSCRIPTION_EDITING_PAGE_NAME) {
      SubscriptionEditingPageBuilder(params)
    }
  }
}