import { KeyboardAvoidMode } from "@kit.ArkUI"
import { AppUtil } from "@pura/harmony-utils"
import { VpnConfigManager } from "../../manager/vpn/VpnConfigManager"
import { Nav } from "../../utils/Nav"
import { SettingsVpnValueInputViewModel } from "./SettingsVpnValueInputPage"
import { SettingsListItemView } from "./views/SettingsListItemView"
import { SettingsVpnMtuInput } from "./views/SettingsVpnMtuInput"
import { JSON } from "@kit.ArkTS"
import { VpnConnector } from "../../manager/vpn/VpnConnector"
import { Validator } from "../../lib/Validator"

@Builder
export function SettingsVpnPageBuilder(_: Object) {
  SettingsVpnPage()
}

@ComponentV2
struct SettingsVpnPage {

  private readonly manager = VpnConfigManager.getInstance()

  private keyboardAvoidMode: KeyboardAvoidMode = KeyboardAvoidMode.OFFSET

  private origin: string = ''

  aboutToAppear() {
    this.origin = JSON.stringify(this.manager.buildRawConfig())
  }

  aboutToDisappear(): void {
    const current = JSON.stringify(this.manager.buildRawConfig())
    if (current === this.origin) {
      return
    }
    VpnConnector.getInstance().reconnectIfNeeded()
  }

  build() {
    NavDestination() {
      List({ space: 32 }) {
        this.buildIPAddressesView()
        this.buildMtuView()
        this.buildRoutesView()
        this.buildDnsesView()
        this.buildApplicationsView()
      }
      .width('100%')
      .height('100%')
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .contentStartOffset(16)
      .contentEndOffset(16)
      .padding({ left: 16, right: 16 })
      .scrollBar(BarState.Off)
      .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .title('设置')
    .onShown(() => {
      this.keyboardAvoidMode = this.getUIContext().getKeyboardAvoidMode()
      this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE_WITH_CARET)
    })
    .onHidden(() => {
      this.getUIContext().setKeyboardAvoidMode(this.keyboardAvoidMode)
    })
    .backgroundColor($r('sys.color.background_secondary'))
  }

  @Builder private buildIPAddressesView() {
    ListItemGroup({ header: this.buildListItemGroupHeader('地址', '在不支持IPv6的网络环境下启用IPv6可能导致无法访问网络') }) {
      ListItem() {
        SettingsListItemView({
          name: 'IPv4地址',
          value: `${VpnConfigManager.ipv4Address.address.address}/${VpnConfigManager.ipv4Address.prefixLength}`,
          isArrowRightVisible: false,
          isSwitchVisible: true,
          isSwitchEnable: false,
          isSwitchOn: this.manager.isIPv4Accepted,
          onSwitchValueChanged: (value) => this.manager.isIPv4Accepted = value
        })
      }
      ListItem() {
        SettingsListItemView({
          name: 'IPv6地址',
          value: `${VpnConfigManager.ipv6Address.address.address}/${VpnConfigManager.ipv6Address.prefixLength}`,
          isArrowRightVisible: false,
          isSwitchVisible: true,
          isSwitchEnable: true,
          isSwitchOn: this.manager.isIPv6Accepted,
          onSwitchValueChanged: (value) => this.manager.isIPv6Accepted = value
        })
      }
    }
    .divider({ strokeWidth: '1px', color: $r('sys.color.comp_divider') })
    .size({ width: '100%' })
    .padding({ left: 12, right: 12 })
    .borderRadius(12)
    .backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder private buildMtuView() {
    ListItemGroup({ header: this.buildListItemGroupHeader('MTU', '最大传输单元，取值范围 576～1500') }) {
      ListItem() {
        Row() {
          Text('最大传输单元')
            .fontSize(14)
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Regular)
          SettingsVpnMtuInput({ mtu: this.manager.mtu, onSubmit: (v) => this.manager.mtu = v })
        }
        .size({ width: '100%', height: 52 })
        .alignItems(VerticalAlign.Center)
      }
    }
    .divider({ strokeWidth: '1px', color: $r('sys.color.comp_divider') })
    .size({ width: '100%' })
    .padding({ left: 12, right: 12 })
    .borderRadius(12)
    .backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder private buildRoutesView() {
    ListItemGroup({ header: this.buildListItemGroupHeader('路由', '应用配置了两条默认路由, 可根据需求配置需要排除的路由') }) {
      ListItem() {
        SettingsListItemView({
          name: '默认',
          value: '0.0.0.0/0、::/0',
          isArrowRightVisible: false,
          isSwitchVisible: false,
          isSwitchEnable: false,
          isSwitchOn: false,
          onSwitchValueChanged: () => {}
        })
      }
      ListItem() {
        SettingsListItemView({
          name: '排除路由',
          value: `${this.manager.excludedRoutes.length}`,
          isArrowRightVisible: true,
          isSwitchVisible: false,
          isSwitchEnable: true,
          isSwitchOn: false,
          onSwitchValueChanged: () => {}
        }).onClick(() => {
          Nav.stack.pushPathByName(Nav.SETTINGS_VPN_VALUE_INPUT_PAGE_NAME, new SettingsVpnValueInputViewModel(
            '排除路由',
            '192.168.0.1/16',
            this.manager.excludedRoutes,
            Validator.validateIPCIDR,
            (values) => this.manager.excludedRoutes = values
          ))
        })
      }
    }
    .divider({ strokeWidth: '1px', color: $r('sys.color.comp_divider') })
    .size({ width: '100%' })
    .padding({ left: 12, right: 12 })
    .borderRadius(12)
    .backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder private buildDnsesView() {
    ListItemGroup({ header: this.buildListItemGroupHeader('DNS', '被代理的应用访问网络时, 优先使用自定义的DNS服务器进行查询, 如果失败会回退到系统预置的DNS进行查询') }) {
      ListItem() {
        SettingsListItemView({
          name: '系统',
          value: '223.5.5.5、2400:3200::1',
          isArrowRightVisible: false,
          isSwitchVisible: false,
          isSwitchEnable: false,
          isSwitchOn: false,
          onSwitchValueChanged: () => {}
        })
      }
      ListItem() {
        SettingsListItemView({
          name: '自定义',
          value: `${this.manager.dnsAddresses.length}`,
          isArrowRightVisible: true,
          isSwitchVisible: false,
          isSwitchEnable: true,
          isSwitchOn: false,
          onSwitchValueChanged: () => {}
        }).onClick(() => {
          Nav.stack.pushPathByName(Nav.SETTINGS_VPN_VALUE_INPUT_PAGE_NAME, new SettingsVpnValueInputViewModel(
            '自定义DNS',
            '8.8.8.8',
            this.manager.dnsAddresses,
            Validator.validateIP,
            (values) => this.manager.dnsAddresses = values
          ))
        })
      }
      ListItem() {
        SettingsListItemView({
          name: '搜索域',
          value: `${this.manager.searchDomains.length}`,
          isArrowRightVisible: true,
          isSwitchVisible: false,
          isSwitchEnable: true,
          isSwitchOn: false,
          onSwitchValueChanged: () => {}
        }).onClick(() => {
          Nav.stack.pushPathByName(Nav.SETTINGS_VPN_VALUE_INPUT_PAGE_NAME, new SettingsVpnValueInputViewModel(
            '搜索域',
            'example.com',
            this.manager.dnsAddresses,
            (value: string) => value,
            (values) => this.manager.searchDomains = values
          ))
        })
      }
    }
    .divider({ strokeWidth: '1px', color: $r('sys.color.comp_divider') })
    .size({ width: '100%' })
    .padding({ left: 12, right: 12 })
    .borderRadius(12)
    .backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder private buildApplicationsView() {
    ListItemGroup({ header: this.buildListItemGroupHeader('应用', '白名单内的应用数据会根据路由被代理, 黑名单内的应用数据不会被代理, 白名单和黑名单不能同时启用') }) {
      ListItem() {
        SettingsListItemView({
          name: '白名单',
          value: `${this.manager.trustedApplications.length}`,
          isArrowRightVisible: true,
          isSwitchVisible: true,
          isSwitchEnable: true,
          isSwitchOn: this.manager.isTrustedApplicationsEnable,
          onSwitchValueChanged: (value) => {
            this.manager.isTrustedApplicationsEnable = value
            if (value) {
              this.manager.isBlockedApplicationsEnable = false
            }
          }
        }).onClick(() => {
          Nav.stack.pushPathByName(Nav.SETTINGS_VPN_VALUE_INPUT_PAGE_NAME, new SettingsVpnValueInputViewModel(
            '应用白名单',
            'com.example.abc',
            this.manager.trustedApplications,
            (value: string) => {
              if (value === AppUtil.getBundleName()) {
                throw new Error('不可以将当前应用添加至应用白名单')
              } else {
                return value
              }
            },
            (values) => this.manager.trustedApplications = values
          ))
        })
      }
      ListItem() {
        SettingsListItemView({
          name: '黑名单',
          value: `${this.manager.blockedApplications.length}`,
          isArrowRightVisible: true,
          isSwitchVisible: true,
          isSwitchEnable: true,
          isSwitchOn: this.manager.isBlockedApplicationsEnable,
          onSwitchValueChanged: (value) => {
            this.manager.isBlockedApplicationsEnable = value
            if (value) {
              this.manager.isTrustedApplicationsEnable = false
            }
          }
        }).onClick(() => {
          Nav.stack.pushPathByName(Nav.SETTINGS_VPN_VALUE_INPUT_PAGE_NAME, new SettingsVpnValueInputViewModel(
            '应用黑名单',
            'com.example.abc',
            this.manager.trustedApplications,
            (value: string) => {
              if (value === AppUtil.getBundleName()) {
                throw new Error('不可以将当前应用添加至应用黑名单')
              } else {
                return value
              }
            },
            (values) => this.manager.trustedApplications = values
          ))
        })
      }
    }
    .divider({ strokeWidth: '1px', color: $r('sys.color.comp_divider') })
    .size({ width: '100%' })
    .padding({ left: 12, right: 12 })
    .borderRadius(12)
    .backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder private buildListItemGroupHeader(title: string, description: string) {
    Column({ space: 6 }) {
      Text(title)
        .size({ width: '100%' })
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
      Text(description)
        .size({ width: '100%' })
        .fontSize(12)
        .fontWeight(FontWeight.Regular)
        .fontColor($r('sys.color.font_tertiary'))
    }
    .size({ width: '100%' })
    .padding({ top: 12, bottom: 12 })
  }
}