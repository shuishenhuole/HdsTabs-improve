import { HdsTabs } from '@hms.hds.hdsBaseComponent';
import {
  hdsEffect,
  hdsMaterial,
  HdsTabsController
} from '@kit.UIDesignKit';
import { deviceInfo } from '@kit.BasicServicesKit'; // 设备信息工具，用于适配不同设备
import { HdsMiniBarButton } from 'hds_button'; // 液态指示器核心按钮组件
import { curves } from '@kit.ArkUI';
import { ZSTabsItem, ZSTabsOptions } from '../common/TabsOptions';
import { getBaseContainerWidth, getBasePositions } from '../utils/getBaseinfo';
import { ZSTabsConstance } from '../common/constant';

@ComponentV2
export struct ZSTabs {
  @Param @Require tabsOption: ZSTabsOptions
  // 当前指示器吸附位置索引（0-3，对应4个页签）
  @Param currentIndicatorIndex: number = 0
  @Event $currentIndicatorIndex: (val: number) => void = (val: number) => {
  }
  aboutToAppear() {

  }
  aboutToDisappear() {

  }
  build() {

  }
}
