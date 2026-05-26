import { ConfigurationConstant, UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { AppUtil } from '@pura/harmony-utils';

export default class EntryAbility extends UIAbility {

  onCreate(): void {
    AppUtil.init(this.context)
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
    } catch {}
  }

  async onWindowStageCreate(windowStage: window.WindowStage) {
    try {
      await windowStage.loadContent('pages/main/MainPage')
      const window = await windowStage.getMainWindow()
      window.setWindowDecorHeight(60)
      window.setWindowDecorVisible(false)
    } catch {}
  }
}