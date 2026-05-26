import { KeyboardAvoidMode, SymbolGlyphModifier } from "@kit.ArkUI"
import { JSON } from "@kit.ArkTS"
import { SubscriptionObject, SubscriptionManager } from "../../manager/subscription/SubscriptionManager"
import { Nav } from "../../utils/Nav"
import { BrandLoading } from "../../utils/BrandLoading"
import { Logger } from "../../utils/Logger"

@Builder
export function SubscriptionEditingPageBuilder(subscription: Object) {
  if (subscription instanceof SubscriptionObject) {
    SubscriptionEditingPage({ subscription })
  }
}

@ComponentV2
struct SubscriptionEditingPage {

  private readonly loading = new BrandLoading(this.getUIContext())
  private readonly manager = SubscriptionManager.getInstance()

  @Require @Param subscription: SubscriptionObject

  @Local private title: string = '添加订阅'
  @Local private isLoading: boolean = false
  @Local private name: string = ''
  @Local private link: string = ''

  private keyboardAvoidMode: KeyboardAvoidMode = KeyboardAvoidMode.OFFSET

  aboutToAppear() {
    this.keyboardAvoidMode = this.getUIContext().getKeyboardAvoidMode()
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE_WITH_CARET)
    this.title = this.subscription.link === '' ? '添加订阅' : '编辑订阅'
    this.name = this.subscription.name
    this.link = this.subscription.link
  }

  aboutToDisappear(): void {
    this.getUIContext().setKeyboardAvoidMode(this.keyboardAvoidMode)
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 32 }) {
          Column({ space: 8 }) {
            Text('订阅名称')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_secondary'))
              .size({ width: '100%' })
              .padding({ left: 12, right: 12 })
            TextInput({ text: this.name })
              .id('ID_NAME')
              .backgroundColor($r('sys.color.comp_background_primary'))
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .fontSize(14)
              .fontColor($r('sys.color.font_primary'))
              .fontWeight(FontWeight.Regular)
              .defaultFocus(true)
              .maxLength(10)
              .enterKeyType(EnterKeyType.Next)
              .onChange((value) => this.name = value.trim())
              .onSubmit(() => {
                try {
                  this.getUIContext().getFocusController().requestFocus('ID_ADDR')
                } catch {}
              })
          }
          Column({ space: 8 }) {
            Text('订阅地址')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_secondary'))
              .size({ width: '100%' })
              .padding({ left: 12, right: 12 })
            TextInput({ text: this.link })
              .id('ID_ADDR')
              .backgroundColor($r('sys.color.comp_background_primary'))
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .fontSize(14)
              .fontColor($r('sys.color.font_primary'))
              .fontWeight(FontWeight.Regular)
              .onChange((value) => this.link = value.trim())
              .onSubmit(() => this.onDoneAction())
          }
        }
        .size({ width: '100%' })
        .padding(16)
      }
      .align(Alignment.Top)
      .size({ width: '100%', height: '100%' })
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .scrollBar(BarState.Off)
      .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .title(this.title)
    .backgroundColor($r('sys.color.background_secondary'))
    .menus([
      {
        value: '确定',
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.checkmark')),
        action: () => this.onDoneAction(),
        isEnabled: this.name.length !== 0 && this.link.length !== 0 && !this.isLoading
      }
    ])
    .onBackPressed(() => this.isLoading)
  }

  private async onDoneAction(): Promise<void> {
    if (this.name.length === 0 || this.link.length === 0) {
      return
    }
    try {
      this.getUIContext().getFocusController().clearFocus()
    } catch {}
    this.loading.open()
    this.isLoading = true
    try {
      this.subscription.name = this.name
      this.subscription.link = this.link
      await this.manager.createOrUpdate(this.subscription)
      Nav.stack.pop()
    } catch (err) {
      Logger.error(`onDoneAction error: ${JSON.stringify(err)}`)
      this.getUIContext().getPromptAction().showToast({ message: (err as Error).message })
    } finally {
      this.isLoading = false
      this.loading.close()
    }
  }
}