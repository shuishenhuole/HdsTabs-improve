import { ZSTabsOptions } from "../common/TabsOptions"
import { DTabs } from "../components/DTabs"
import deviceInfo from "@ohos.deviceInfo"
import { HTabs } from "../components/HTabs"


@ComponentV2
export struct ZSTabs {
  @Param @Require tabsOption: ZSTabsOptions
  @Param currentIndex: number = 0
  @Event $currentIndex: (val: number) => void = (val: number) => {
  }

  build() {
    Column() {
      if (deviceInfo.sdkApiVersion < 23) {
        DTabs({
          currentIndex: this.currentIndex,
          onCurrentIndexChange: (index: number) => {
            this.$currentIndex(index)
          },
          tabsOption: this.tabsOption,
        })
      } else {
        HTabs({
          currentIndex: this.currentIndex,
          onCurrentIndexChange: (index: number) => {
            this.$currentIndex(index)
          },
          tabsOption: this.tabsOption,
        })
      }
    }
  }
}
