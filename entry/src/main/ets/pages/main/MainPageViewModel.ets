import { Nav } from "../../utils/Nav"

@ObservedV2
export class MainPageViewModel {

  @Trace mode = NavigationMode.Auto

  public onNavigationModeChange(mode: NavigationMode): void {
    if (this.mode === NavigationMode.Split && mode === NavigationMode.Stack && Nav.stack.getAllPathName().length === 1) {
      Nav.stack.clear(false)
    }
    if (mode === NavigationMode.Split) {
      const names = Nav.stack.getAllPathName()
      if (names.length === 0) {
        this.switchToTab(Nav.MAIN_TAB_SUBSCRIPTION_LIST_PAGE_NAME)
      }
    }
    this.mode = mode
  }

  public switchToTab(name: string): void {
    if (name.startsWith("MAIN_TAB_")) {
      const names = Nav.stack.getAllPathName()
      if (names[0] === name) {
        Nav.stack.popToName(name)
        return
      }
      Nav.stack.clear(false)
      Nav.stack.pushPathByName(name, this, this.mode !== NavigationMode.Split)
    }
  }
}