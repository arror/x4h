import { KeyboardAvoidMode } from "@kit.ArkUI"

@Builder
export function SettingsVpnValueInputPageBuilder(vm: Object) {
  if (vm instanceof SettingsVpnValueInputViewModel) {
    SettingsVpnValueInputPage({ vm })
  }
}

export class SettingsVpnValueInputViewModel {

  readonly title: string
  readonly placeholder: string
  readonly values: Array<string> = []
  readonly validate: (_:string) => string
  readonly onSubmit: (_:Array<string>) => void



  constructor(
    title: string,
    placeholder: string,
    values: Array<string>,
    validate: (_:string) => string,
    onSubmit: (_:Array<string>) => void
  ) {
    this.title = title
    this.placeholder = placeholder
    this.values = values
    this.validate = validate
    this.onSubmit = onSubmit
  }
}

@ComponentV2
struct SettingsVpnValueInputPage {

  @Require @Param vm: SettingsVpnValueInputViewModel

  @Local value: string = ''
  @Local values: Array<string> = []
  @Local isSaveEnable: boolean = false

  private keyboardAvoidMode: KeyboardAvoidMode = KeyboardAvoidMode.OFFSET

  aboutToAppear() {
    this.values.push(...Array.from(this.vm.values))
  }

  build() {
    NavDestination() {
      List({ space: 32 }) {
        ListItemGroup() {
          ForEach(this.values, (value: string) => {
            ListItem() {
              this.buildValueView(value)
            }
          })
          ListItem() {
            this.buildValueInputView()
          }
        }
        .divider({ strokeWidth: '1px', color: $r('sys.color.comp_divider'), startMargin: 12, endMargin: 12 })
        .borderRadius(12)
        .backgroundColor($r('sys.color.comp_background_primary'))
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
    .title(this.vm.title)
    .onShown(() => {
      this.keyboardAvoidMode = this.getUIContext().getKeyboardAvoidMode()
      this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE_WITH_CARET)
    })
    .onHidden(() => {
      this.getUIContext().setKeyboardAvoidMode(this.keyboardAvoidMode)
    })
    .backgroundColor($r('sys.color.background_secondary'))
  }

  @Builder
  private buildValueView(value: string) {
    Row({ space: 8 }) {
      SymbolGlyph($r('sys.symbol.minus_circle_fill'))
        .fontColor([$r('sys.color.warning')])
        .onClick(() => {
          animateToImmediately({ duration: 250, curve: Curve.EaseInOut }, () => {
            this.values.splice(this.values.indexOf(value), 1)
            this.vm.onSubmit(this.values)
          })
        })
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .fontColor($r('sys.color.font_primary'))
        .layoutWeight(1)
        .height(24)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .ellipsisMode(EllipsisMode.CENTER)
    }
    .size({ width: '100%', height: 44 })
    .padding({ left: 12, right: 12 })
  }

  @Builder
  private buildValueInputView() {
    Row({ space: 8 }) {
      SymbolGlyph($r('sys.symbol.plus_circle_fill'))
        .fontColor([$r('sys.color.font_emphasize')])
      TextInput({ text: this.value, placeholder: this.vm.placeholder })
        .padding(0)
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .fontColor($r('sys.color.font_primary'))
        .placeholderFont({ size: 14 })
        .placeholderColor($r('sys.color.font_fourth'))
        .layoutWeight(1)
        .height('100%')
        .onChange((v) => this.value = v)
        .enterKeyType(EnterKeyType.Done)
        .onSubmit(async () => {
          const trimmed = this.value.trim()
          if (trimmed === '') {
            this.value = ''
            return
          }
          try {
            const result = this.vm.validate(trimmed)
            this.value = ''
            if (this.values.includes(result)) {
              return
            }
            this.values.push(result)
            this.vm.onSubmit(this.values)
          } catch (e) {
            this.getUIContext().getPromptAction().showToast({ message: (e as Error).message, alignment: Alignment.Center })
          }
        })
    }
    .size({ width: '100%', height: 44 })
    .padding({ left: 12, right: 12 })
  }
}