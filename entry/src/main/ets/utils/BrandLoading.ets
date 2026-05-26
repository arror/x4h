import { CustomDialog } from './CustomDialog'
import { ComponentContent } from '@kit.ArkUI'

@Builder
function buildBrandLoading() {
  Stack({ alignContent: Alignment.Center }) {
    LoadingProgress()
      .color($r('sys.color.font_primary'))
      .size({ width: 54, height: 54 })
  }
  .borderRadius(16)
  .backgroundColor(Color.Transparent)
  .size({ width: 80, height: 80 })
}

export class BrandLoading {

  private readonly context: UIContext

  private dialog: CustomDialog<Object> | undefined

  constructor(context: UIContext) {
    this.context = context
  }

  public open(): void {
    const content = new ComponentContent(this.context, wrapBuilder(buildBrandLoading))
    this.dialog = new CustomDialog(this.context, content, {
      autoCancel: false,
      onWillDismiss: () => {},
      maskColor: Color.Transparent
    })
    this.dialog.open()
  }

  public close(): void {
    if (this.dialog) {
      this.dialog.close()
    }
  }
}