import { ZSTabsOptions } from "../common/TabsOptions"
import { DTabs } from "../components/DTabs"
import { HTabs } from "../components/HTabs"

@ComponentV2
export struct ZSTabs {
  @Param @Require tabsOption: ZSTabsOptions
  @Param currentIndicatorIndex: number = 0
  @Event $currentIndicatorIndex: (val: number) => void = (val: number) => {
  }
  aboutToAppear() {

  }
  aboutToDisappear() {

  }
  build() {
    Column(){
      Text(this.currentIndicatorIndex.toString())
      DTabs({
        tabsOption:this.tabsOption,
        currentIndicatorIndex:this.currentIndicatorIndex!!
      })
    }
  }
}
