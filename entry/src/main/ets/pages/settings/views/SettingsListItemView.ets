@ComponentV2
export struct SettingsListItemView {

  @Require @Param name: string
  @Require @Param value: string
  @Require @Param isArrowRightVisible: boolean
  @Require @Param isSwitchVisible: boolean
  @Require @Param isSwitchEnable: boolean
  @Require @Param isSwitchOn: boolean
  @Require @Param onSwitchValueChanged: (_:boolean) => void

  build() {
    Row() {
      Text(this.name)
        .fontSize(14)
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Regular)
      Row({ space: 8 }) {
        Text(this.value)
          .fontSize(14)
          .fontColor($r('sys.color.font_secondary'))
          .fontWeight(FontWeight.Regular)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor([$r('sys.color.font_primary')])
          .visibility(this.isArrowRightVisible ? Visibility.Visible : Visibility.None)
        Divider()
          .vertical(true)
          .size({ height: 20 })
          .visibility(this.isSwitchVisible ? Visibility.Visible : Visibility.None)
        Toggle({ isOn: this.isSwitchOn, type: ToggleType.Switch })
          .onChange((on) => this.onSwitchValueChanged(on))
          .enabled(this.isSwitchEnable)
          .visibility(this.isSwitchVisible ? Visibility.Visible : Visibility.None)
      }
      .alignItems(VerticalAlign.Center)
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
    .size({ width: '100%', height: 52 })
  }
}