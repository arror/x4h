import { AppUtil, FileUtil, PreviewUtil } from "@pura/harmony-utils"
import { systemShare } from "@kit.ShareKit"
import { uniformTypeDescriptor } from "@kit.ArkData"
import {
  CoreConfigManager,
  CoreLogAddressMask,
  CoreLogAddressMaskNameOf,
  CoreLogAddressMasks,
  CoreLogLevel,
  CoreLogLevelNameOf,
  CoreLogLevels
} from "../../manager/core/CoreConfigManager"
import { VpnConnector } from "../../manager/vpn/VpnConnector"

@Builder
export function SettingsLogPageBuilder(_: Object) {
  SettingsLogPage()
}

@ComponentV2
struct SettingsLogPage {

  @Local paths: Array<string> = []

  private readonly scroller = new ListScroller()

  private readonly log = CoreConfigManager.getInstance().log

  private origin: string = ''

  aboutToAppear() {
    FileUtil.listFile(FileUtil.getFilesDirPath('log')).then((paths) => this.paths = paths.reverse())
    this.origin = JSON.stringify(this.log.buildRawConfig())
  }

  aboutToDisappear(): void {
    const current = JSON.stringify(this.log.buildRawConfig())
    if (current === this.origin) {
      return
    }
    VpnConnector.getInstance().reconnectIfNeeded()
  }

  build() {
    NavDestination() {
      List({ scroller: this.scroller, space: 32 }) {
        ListItemGroup() {
          ListItem() {
            PickerView({
              name: '日志等级',
              option: this.log.level,
              optionDisplay: (option) => {
                return CoreLogLevelNameOf(option as CoreLogLevel)
              },
              options: CoreLogLevels,
              onOptionChanged: (value) => this.log.level = value as CoreLogLevel
            })
          }
          ListItem() {
            PickerView({
              name: '地址遮罩',
              option: this.log.addressMask,
              optionDisplay: (option) => {
                return CoreLogAddressMaskNameOf(option as CoreLogAddressMask)
              },
              options: CoreLogAddressMasks,
              onOptionChanged: (value) => this.log.addressMask = value as CoreLogAddressMask
            })
          }
        }
        .divider({ strokeWidth: '1px', color: $r('sys.color.comp_divider'), startMargin: 12, endMargin: 12 })
        .size({ width: '100%' })
        .borderRadius(12)
        .backgroundColor($r('sys.color.comp_background_primary'))

        ListItemGroup() {
          ForEach((this.paths), (name: string) => {
            ListItem() {
              LogFileView({ name })
            }
            .size({ width: '100%' })
            .swipeAction({ end: { builder: this.buildSwiperActions(name) } })
            .onClick(() => PreviewUtil.openPreviewEasy(FileUtil.getUriFromPath(FileUtil.getFilesDirPath('log', name))))
          })
        }
        .divider({ strokeWidth: '1px', color: $r('sys.color.comp_divider'), startMargin: 12, endMargin: 12 })
        .size({ width: '100%' })
        .borderRadius(12)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .clip(true)
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
    .title('日志')
    .backgroundColor($r('sys.color.background_secondary'))
  }

  @Builder
  private buildSwiperActions(name: string) {
    Row() {
      Button('导出')
        .fontSize(12)
        .size({ width: 54, height: '100%' })
        .borderRadius(0)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor($r('sys.color.background_emphasize'))
        .controlSize(ControlSize.SMALL)
        .onClick(() => {
          const data: systemShare.SharedData = new systemShare.SharedData({
            utd: uniformTypeDescriptor.UniformDataType.FILE,
            uri: FileUtil.getUriFromPath(FileUtil.getUriFromPath(FileUtil.getFilesDirPath('log', name)))
          })
          const controller = new systemShare.ShareController(data)
          controller.show(AppUtil.getContext(), {
            previewMode: systemShare.SharePreviewMode.DEFAULT,
            selectionMode: systemShare.SelectionMode.SINGLE
          }).then(() => this.scroller.closeAllSwipeActions()) .catch()
        })
      Button('删除')
        .fontSize(12)
        .size({ width: 54, height: '100%' })
        .borderRadius(0)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor($r('sys.color.warning'))
        .controlSize(ControlSize.SMALL)
        .onClick(() => {
          FileUtil.unlinkSync(FileUtil.getFilesDirPath('log', name))
          this.paths.splice(this.paths.indexOf(name), 1)
          this.scroller.closeAllSwipeActions()
        })
    }
    .size({ height: '100%' })
    .backgroundColor($r('sys.color.background_secondary'))
  }
}

@ComponentV2
struct PickerView {

  @Require @Param name: string
  @Require @Param option: string
  @Require @Param optionDisplay: (_:string) => string
  @Require @Param options: Array<string>
  @Require @Param onOptionChanged: (_:string) => void

  build() {
    Row() {
      Text(this.name)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
      Text(this.optionDisplay(this.option))
        .fontSize(14)
        .fontWeight(FontWeight.Normal)
        .fontColor($r('sys.color.text_color_selected'))
        .bindMenu(this.buildMenu())
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
    .size({ width: '100%', height: 44 })
    .padding({ left: 12, right: 12 })
  }

  @Builder
  private buildMenu() {
    Menu() {
      ForEach(this.options, (option: string) => {
        MenuItem({ content: this.optionDisplay(option) })
          .contentFont({ size: 14 })
          .height(36)
          .contentFontColor(this.option === option ? $r('sys.color.text_color_selected') : $r('sys.color.menu_text_normal_color'))
          .onChange(() => this.onOptionChanged(option))
      })
    }
  }
}

@ComponentV2
struct LogFileView {

  @Require @Param name: string

  build() {
    Row() {
      Text(this.name)
        .fontSize(14)
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Regular)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .ellipsisMode(EllipsisMode.CENTER)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor([$r('sys.color.font_tertiary')])
    }
    .alignItems(VerticalAlign.Center)
    .padding({ left: 12, right: 12 })
    .size({ width: '100%', height: 44 })
  }
}