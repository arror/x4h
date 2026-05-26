import { SymbolGlyphModifier } from "@kit.ArkUI"
import { Nav } from "../../utils/Nav"
import { SubscriptionObject, SubscriptionManager, SubscriptionDownloader } from "../../manager/subscription/SubscriptionManager"
import { JSON } from "@kit.ArkTS"
import { ResponseRegion } from "../../utils/ResponseRegion"
import { Logger } from "../../utils/Logger"
import { AppUtil } from "@pura/harmony-utils"

@Builder
export function SubscriptionListPageBuilder(_:Object) {
  SubscriptionListPage()
}

@ComponentV2
struct SubscriptionListPage {

  private readonly manager = SubscriptionManager.getInstance()

  private readonly scroller = new ListScroller()

  build() {
    NavDestination() {
      if (this.manager.subscriptions.length === 0) {
        Column() {
          Image($r('app.media.404'))
            .aspectRatio(4 / 3)
            .size({ width: '100%' })
            .constraintSize({ maxWidth: 320 })
        }
        .padding({ bottom: this.getUIContext().px2vp(AppUtil.getNavigationIndicatorHeight()) })
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .size({ width: '100%', height: '100%' })
      } else {
        List({ scroller: this.scroller, space: 12 }) {
          ForEach(this.manager.subscriptions, (subscription: SubscriptionObject) => {
            ListItem() {
              SubscriptionItemView({ manager: this.manager, subscription: subscription })
            }
            .borderRadius(12)
            .backgroundColor($r('sys.color.comp_background_primary'))
            .clip(true)
          })
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
    }
    .title('订阅管理')
    .menus([
      {
        value: '添加',
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.plus')),
        action: () => Nav.stack.pushPathByName(Nav.SUBSCRIPTION_EDITING_PAGE_NAME, SubscriptionObject.create())
      }
    ])
    .backgroundColor($r('sys.color.background_secondary'))
  }
}

@ComponentV2
struct SubscriptionItemView {

  private readonly downloader = SubscriptionDownloader.getInstance()

  @Computed private get isLoading(): boolean {
    return this.downloader.ids.has(this.subscription.id)
  }

  @Require @Param manager: SubscriptionManager
  @Require @Param subscription: SubscriptionObject

  @Computed private get isSelected(): boolean {
    return this.manager.current.id === this.subscription.id
  }

  build() {
    Row({ space: 12 }) {
      SymbolGlyph($r('sys.symbol.checkmark'))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor([$r('sys.color.font_emphasize')])
        .visibility(this.isSelected ? Visibility.Visible : Visibility.Hidden)
      Column({ space: 8 }) {
        Text(this.subscription.name)
          .fontSize(14)
          .fontColor(this.isSelected ? $r('sys.color.font_emphasize') : $r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .ellipsisMode(EllipsisMode.END)
          .maxLines(1)
          .alignSelf(ItemAlign.Stretch)
        Text(this.subscription.timestamp)
          .fontSize(10)
          .fontColor($r('sys.color.font_secondary'))
          .alignSelf(ItemAlign.Stretch)
      }
      .layoutWeight(1)
      Row({ space: 16 }) {
        if (this.isLoading) {
          LoadingProgress()
            .size({ width: 20, height: 20 })
            .foregroundColor($r('sys.color.font_secondary'))
        } else {
          Stack() {
            SymbolGlyph($r('sys.symbol.more'))
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor([$r('sys.color.font_secondary')])
              .size({ width: 20, height: 20 })
          }
          .responseRegion(ResponseRegion.edge(12))
          .bindMenu(this.buildMenu())
        }
      }
    }
    .padding(12)
    .onClick(() => this.manager.setCurrent(this.subscription))
  }

  @Builder
  private buildMenu() {
    Menu() {
      MenuItem({ content: '更新' })
        .contentFont({ size: 14 })
        .height(40)
        .contentFontColor($r('sys.color.font_emphasize'))
        .onClick(() => this.onUpdateAction())
      MenuItem({ content: '编辑' })
        .contentFont({ size: 14 })
        .height(40)
        .contentFontColor($r('sys.color.font_emphasize'))
        .onClick(() => this.onEditingAction())
      MenuItem({ content: '删除' })
        .contentFont({ size: 14 })
        .height(40)
        .contentFontColor($r('sys.color.warning'))
        .onClick(() => this.onDeleteAction())
    }
  }

  private async onUpdateAction(): Promise<void> {
    try {
      await this.manager.createOrUpdate(this.subscription)
    } catch (err) {
      Logger.error(`onUpdateAction error: ${JSON.stringify(err)}`)
      this.getUIContext().getPromptAction().showToast({ message: (err as Error).message })
    }
  }

  private onEditingAction(): void {
    Nav.stack.pushPathByName(Nav.SUBSCRIPTION_EDITING_PAGE_NAME, this.subscription)
  }

  private onDeleteAction() {
    this.manager.delete(this.subscription)
  }
}