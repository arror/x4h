import { Nav } from "../../../utils/Nav"

@ComponentV2
export struct MainLogEntranceView {

  build() {
    Row({ space: 8 }) {
      Column({ space: 8 }) {
        Text('日志')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
        Text('所有日志会输出到同一个文件中')
          .fontSize(12)
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.font_tertiary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor([$r('sys.color.font_primary')])
    }
    .size({ width: '100%' })
    .padding(12)
    .borderRadius(12)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .onClick(() => Nav.stack.pushPathByName(Nav.SETTINGS_LOG_PAGE_NAME, Object))
  }
}