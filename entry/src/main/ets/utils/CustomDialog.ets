import { promptAction } from "@kit.ArkUI"

export class CustomDialog<T extends object> {

  private readonly context: UIContext
  private readonly content: ComponentContent<T>
  private readonly options: promptAction.BaseDialogOptions

  public constructor(context: UIContext, content: ComponentContent<T>, options: promptAction.BaseDialogOptions) {
    this.context = context
    this.content = content
    this.options = options
  }

  public async open(): Promise<void> {
    try {
      await this.context.getPromptAction().openCustomDialog(this.content, this.options)
    } catch {}
  }

  public async close(): Promise<void> {
    try {
      await this.context.getPromptAction().closeCustomDialog(this.content)
    } catch {}
  }
}