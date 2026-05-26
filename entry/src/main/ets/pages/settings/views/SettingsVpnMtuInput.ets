@ComponentV2
export struct SettingsVpnMtuInput {

  @Require @Param mtu: number
  @Require @Param onSubmit: (_:number) => void

  @Local private text: string = ''

  aboutToAppear(): void {
    this.text = `${this.mtu}`
  }

  build() {
    TextInput({ text: this.text })
      .textAlign(TextAlign.End)
      .maxLength(4)
      .padding(0)
      .borderRadius(0)
      .backgroundColor(Color.Transparent)
      .layoutWeight(1)
      .fontSize(14)
      .fontColor($r('sys.color.font_secondary'))
      .fontWeight(FontWeight.Regular)
      .inputFilter('^\\d+$')
      .size({ height: '100%' })
      .onChange((v) => this.text = v)
      .onSubmit(() => {
        const v = Number.parseInt(this.text, 10)
        if (!this.text || Number.isNaN(v) || typeof v !== 'number') {
          this.text = `${this.mtu}`
          return this.onSubmit(this.mtu)
        } else {
          const temp = Math.min(Math.max(v, 576), 1500)
          this.text = `${temp}`
          return this.onSubmit(temp)
        }
      })
  }
}