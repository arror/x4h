import { AppUtil } from "@pura/harmony-utils"
import { window } from "@kit.ArkUI"

@ObservedV2
export class NavigationIndicatorHeightObserver {

  @Trace height: number = 0

  private constructor() {
    this.updateHeight()
    AppUtil.getMainWindow().on('avoidAreaChange', () => this.updateHeight())
  }

  private static instance: NavigationIndicatorHeightObserver | undefined

  static getInstance(): NavigationIndicatorHeightObserver {
    if (NavigationIndicatorHeightObserver.instance === undefined) {
      NavigationIndicatorHeightObserver.instance = new NavigationIndicatorHeightObserver()
    }
    return NavigationIndicatorHeightObserver.instance
  }

  private updateHeight() {
    try {
      const area = AppUtil.getMainWindow().getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
      this.height = AppUtil.getUIContext().px2vp(area.bottomRect.height)
    } catch (error) {
      this.height = 0
    }
  }
}