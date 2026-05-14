import { HdsTabs } from '@hms.hds.hdsBaseComponent';
import {
  hdsMaterial, HdsTabsController
} from '@kit.UIDesignKit';
import { curves } from '@kit.ArkUI';
import { ZSTabsItem, ZSTabsOptions } from '../common/TabsOptions';
import { getBaseContainerWidth, getBasePositions } from '../utils/getBaseinfo';
import { ZSTabsConstance } from '../common/constant';
import { HdsMiniBarButton } from './HdsMiniBarButton';
import { resourceType } from '../utils/tabtype';
import {
  ANIM_DURATION_ICON,
  ANIM_DURATION_NEAR_ANCHOR,
  ANIM_DURATION_RESET,
  ANIM_DURATION_SWITCH,
  BAR_BORDER_RADIUS,
  BAR_MOVING_HEIGHT,
  BAR_MOVING_WIDTH,
  BAR_RESTING_HEIGHT,
  BAR_RESTING_WIDTH,
  BLUR_AMOUNT,
  EDGE_DRAG_DAMPING,
  INDICATOR_CONTAINER_WIDTH,
  TAB_BAR_HEIGHT
} from './HTabsConstants';
import { calcAnchorPositions, calcSlotWidth } from './HTabsUtils';
import { HTabsIndicator } from './HTabsIndicator';

@ComponentV2
export struct HTabs {
  @Param @Require tabsOption: ZSTabsOptions
  @Param currentIndex: number = 0
  @Event onCurrentIndexChange: (val: number) => void = (val: number) => {
  }

  private readonly BASE_POSITIONS: number[] = getBasePositions(this.tabsOption.tabItems.length)
  private readonly BASE_CONTAINER_WIDTH: number = getBaseContainerWidth(this.tabsOption.tabItems.length)
  @Local private indicatorContainerWidth: number = getBaseContainerWidth(this.tabsOption.tabItems.length)

  private indicator: HTabsIndicator = new HTabsIndicator();
  private tabsController: HdsTabsController = new HdsTabsController();
  @Local private activeTabIndex: number = 0;
  @Local selectedTabIndex: number = 0;
  private tabTitles: string[] = this.tabsOption.tabItems.map((item: ZSTabsItem) => item.title)
  private tabIcons: Resource[] = this.tabsOption.tabItems.map((item: ZSTabsItem) => item.icon)

  private getAnchorPositions(): number[] {
    return calcAnchorPositions(this.indicatorContainerWidth, this.BASE_CONTAINER_WIDTH, this.BASE_POSITIONS);
  }

  private getAnchorPosition(): number {
    return this.getAnchorPositions()[this.currentIndex];
  }

  private getSlotWidth(): number {
    return calcSlotWidth(this.indicatorContainerWidth, this.BASE_CONTAINER_WIDTH);
  }

  @Monitor("activeTabIndex")
  private onActiveTabChange(): void {
    if (this.indicator.isProgrammaticChange) {
      return;
    }
    if (this.activeTabIndex === this.currentIndex) {
      return;
    }

    this.indicator.enterMoving(this.activeTabIndex);
    this.getUIContext().animateTo({ duration: ANIM_DURATION_SWITCH, curve: curves.springMotion() }, () => {
      this.indicator.animatedBarWidth = BAR_MOVING_WIDTH;
      this.indicator.animatedBarHeight = BAR_MOVING_HEIGHT;
      this.onCurrentIndexChange(this.activeTabIndex)
      this.indicator.displayIndex = this.activeTabIndex;
      this.indicator.dragOffsetX = 0;
    });
    setTimeout(() => {
      this.indicator.enterResting(this.activeTabIndex);
      this.getUIContext().animateTo({ curve: curves.springMotion() }, () => {
        this.indicator.animatedBarWidth = BAR_RESTING_WIDTH;
        this.indicator.animatedBarHeight = BAR_RESTING_HEIGHT;
        this.indicator.resetDeformation();
        this.indicator.displayIndex = this.activeTabIndex;
      });
    }, ANIM_DURATION_SWITCH + 10);
  }

  aboutToAppear() {
  }

  aboutToDisappear() {
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      HdsTabs({
        controller: this.tabsController,
        index: this.activeTabIndex
      }) {
        ForEach(this.tabsOption.tabItems, (item: ZSTabsItem, index: number) => {
          TabContent() {
            item.builder.builder()
          }
          .tabBar(this.TabItemBuilder(
            item.title,
            item.icon,
            index,
            item.color,
            item.selectColor ?? item.color
          ))
        })
      }
      .onChange((index: number) => {
        this.selectedTabIndex = index;
        this.activeTabIndex = index;
      })
      .barHeight(TAB_BAR_HEIGHT)
      .animationDuration(0)
      .scrollable(false)
      .vertical(false)
      .barPosition(BarPosition.End)
      .barOverlap(true)
      .barFloatingStyle({
        barWidth: {
          smallWidth: this.BASE_CONTAINER_WIDTH,
          mediumWidth: this.BASE_CONTAINER_WIDTH,
          largeWidth: this.BASE_CONTAINER_WIDTH
        },
        adaptToHandedness: true,
        lightColor: this.tabsOption.maskColor,
        barBottomMargin: this.tabsOption.barBottomMargin ?? ZSTabsConstance.barBottomMargin,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        }
      })

      Column() {
        Row() {
          Stack() {
            HdsMiniBarButton({
              maskColor: '#00ffffff',
              barWidth: this.indicator.animatedBarWidth,
              barHeight: this.indicator.animatedBarHeight,
              materialType: hdsMaterial.MaterialType.IMMERSIVE,
              materialLevel: hdsMaterial.MaterialLevel.EXQUISITE,
            }) {
              Column({ space: 0 }) {
                if (this.tabIcons[this.indicator.displayIndex].type === resourceType.symbol) {
                  SymbolGlyph(this.tabIcons[this.indicator.displayIndex])
                    .fontSize(30)
                    .fontColor([this.tabsOption.tabItems[0].selectColor ??
                      this.tabsOption.tabItems[0].color])
                    .blur((this.indicator.isMoving && !this.indicator.isNearAnchor) ? BLUR_AMOUNT : 0)
                    .borderRadius(12)
                    .padding(2)
                    .animation({ duration: ANIM_DURATION_ICON, curve: Curve.Smooth })

                } else if (this.tabIcons[this.indicator.displayIndex].type === resourceType.image) {
                  Image(this.tabIcons[this.indicator.displayIndex])
                    .width(30)
                    .height(30)
                    .objectFit(ImageFit.Contain)
                    .fillColor(this.tabsOption.tabItems[0].selectColor ??
                      this.tabsOption.tabItems[0].color)
                    .blur((this.indicator.isMoving && !this.indicator.isNearAnchor) ? BLUR_AMOUNT : 0)
                    .borderRadius(12)
                    .padding(2)
                    .animation({ duration: ANIM_DURATION_ICON, curve: Curve.Smooth })
                }

                Text(this.tabTitles[this.indicator.displayIndex])
                  .fontSize(9)
                  .fontColor(this.tabsOption.tabItems[0].selectColor ??
                    this.tabsOption.tabItems[0].color)
                  .fontWeight(FontWeight.Normal)
                  .blur((this.indicator.isMoving && !this.indicator.isNearAnchor) ? BLUR_AMOUNT : 0)
                  .padding(2)
                  .borderRadius(15)
                  .animation({ curve: curves.springMotion() })
              }
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .width('100%')
              .height('100%')
              .borderRadius(BAR_BORDER_RADIUS)
            }

            Row() {
            }
            .width(BAR_RESTING_WIDTH)
            .height(BAR_RESTING_HEIGHT)
            .borderRadius(BAR_BORDER_RADIUS)
            .backgroundColor(Color.Transparent)
            .animation({ curve: curves.springMotion() })
          }
          .borderRadius(BAR_BORDER_RADIUS)
          .clip(false)
          .width(80)
          .height(80)
        }
        .borderRadius(BAR_BORDER_RADIUS)
        .clip(false)
        .translate({ x: this.indicator.dragOffsetX })
        .gesture(
          PanGesture({ direction: PanDirection.Horizontal })
            .onActionStart(() => {
              this.indicator.enterMoving(this.currentIndex);
              this.getUIContext().animateTo({ curve: curves.springMotion() }, () => {
                this.indicator.animatedBarWidth = BAR_MOVING_WIDTH;
                this.indicator.animatedBarHeight = BAR_MOVING_HEIGHT;
              });
            })
            .onActionUpdate((event: GestureEvent) => {
              const velocity = event.offsetX - this.indicator.lastOffsetX;
              this.indicator.lastOffsetX = event.offsetX;

              if (this.indicator.isMoving) {
                this.indicator.updateVelocityDeformation(velocity);
              }

              if (this.currentIndex === 0 && event.offsetX < 0) {
                this.indicator.dragOffsetX = event.offsetX * EDGE_DRAG_DAMPING;
              } else if (this.currentIndex === 3 && event.offsetX > 0) {
                this.indicator.dragOffsetX = event.offsetX * EDGE_DRAG_DAMPING;
              } else {
                this.indicator.dragOffsetX = event.offsetX;
              }

              if (this.indicator.isMoving) {
                const currentX = this.getAnchorPosition() + this.indicator.dragOffsetX;
                const changed = this.indicator.checkNearAnchor(currentX, this.getAnchorPositions());
                if (changed && !this.indicator.isMoving) {
                  this.getUIContext().animateTo({ duration: ANIM_DURATION_NEAR_ANCHOR, curve: Curve.EaseInOut }, () => {
                  });
                }
              }
            })
            .onActionEnd(() => {
              const slotWidth = this.getSlotWidth();
              const movedSlots = Math.round(this.indicator.dragOffsetX / slotWidth);
              let newIndex = this.currentIndex + movedSlots;
              newIndex = Math.max(0, Math.min(3, newIndex));

              if (newIndex !== this.currentIndex) {
                this.indicator.isProgrammaticChange = true;
                this.indicator.isMoving = true;
                this.getUIContext().animateTo({ duration: ANIM_DURATION_SWITCH, curve: curves.springMotion() }, () => {
                  this.onCurrentIndexChange(newIndex)
                  this.indicator.displayIndex = newIndex;
                  this.indicator.dragOffsetX = 0;
                });
                setTimeout(() => {
                  this.indicator.enterResting(newIndex);
                  this.tabsController.changeIndex(newIndex);
                  this.selectedTabIndex = newIndex;
                  this.activeTabIndex = newIndex;
                  this.getUIContext().animateTo({ curve: curves.springMotion() }, () => {
                    this.indicator.animatedBarWidth = BAR_RESTING_WIDTH;
                    this.indicator.animatedBarHeight = BAR_RESTING_HEIGHT;
                    this.indicator.resetDeformation();
                    this.indicator.displayIndex = newIndex;
                  });
                }, ANIM_DURATION_SWITCH + 10);
              } else {
                this.indicator.isMoving = false;
                this.getUIContext().animateTo({ duration: ANIM_DURATION_RESET, curve: curves.springMotion() }, () => {
                  this.indicator.animatedBarWidth = BAR_RESTING_WIDTH;
                  this.indicator.animatedBarHeight = BAR_RESTING_HEIGHT;
                  this.indicator.resetDeformation();
                  this.indicator.dragOffsetX = 0;
                });
              }
            })
        )
        .position({
          x: this.getAnchorPosition()
        })
        .animation({ curve: curves.springMotion() })
      }
      .margin({ bottom: this.tabsOption.barBottomMargin ?? ZSTabsConstance.barBottomMargin })
      .width(INDICATOR_CONTAINER_WIDTH)
      .height(TAB_BAR_HEIGHT)
      .clip(false)
      .hitTestBehavior(HitTestMode.Transparent)
      .backgroundColor(Color.Transparent)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        const newWidth = Number(newValue.width);
        if (newWidth > 0 && Math.abs(newWidth - this.indicatorContainerWidth) > 0.5) {
          this.indicatorContainerWidth = newWidth;
        }
      })
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  @Builder
  TabItemBuilder(title: string, icon: string | Resource, index: number, color: ResourceColor,
    selectColor: ResourceColor) {
    Column() {
      if (typeof icon === 'string') {
        Text(icon)
          .fontSize(24)
          .fontColor(index === this.selectedTabIndex ? selectColor : color)
          .margin({ bottom: 2 })
      } else {
        if (icon.type === resourceType.symbol) {
          SymbolGlyph(icon)
            .fontSize(25)
            .fontColor([index === this.selectedTabIndex ? selectColor : color])
        } else if (icon.type === resourceType.image) {
          Image(icon)
            .width(25)
            .height(25)
            .objectFit(ImageFit.Contain)
            .margin({ bottom: 2 })
            .fillColor(index === this.selectedTabIndex ? selectColor : color)
        }
      }
      Text(title)
        .fontSize(10)
        .fontColor(index === this.selectedTabIndex ? selectColor : color)
        .fontWeight(this.selectedTabIndex === index ? FontWeight.Bold : FontWeight.Regular)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
