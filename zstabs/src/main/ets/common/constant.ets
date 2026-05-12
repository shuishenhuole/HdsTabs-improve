/**
 * TabBar基础配置常量
 * 定义TabBar的尺寸、位置等基础参数
 */
export class TabConstants {
  /** 4个页签的基准锚点位置（vp），用于计算指示器吸附位置 */
  static readonly BASE_POSITIONS: number[] = [8.5, 85, 162.5, 241];
  /** TabBar基准容器宽度（vp），用于屏幕适配计算 */
  static readonly BASE_CONTAINER_WIDTH: number = 330;
  /** TabBar高度（vp） */
  static readonly BAR_HEIGHT: number = 59;
  /** 小屏幕下的TabBar宽度（vp） */
  static readonly BAR_WIDTH_SMALL: number = 330;
  /** 中屏幕下的TabBar宽度（vp） */
  static readonly BAR_WIDTH_MEDIUM: number = 330;
  /** 大屏幕下的TabBar宽度（vp） */
  static readonly BAR_WIDTH_LARGE: number = 330;
  /** TabBar底部间距（vp），避免被系统导航栏遮挡 */
  static readonly BAR_BOTTOM_MARGIN: number = 28;
  /** Tab页签总数量 */
  static readonly TAB_COUNT: number = 4;
  /** 页签插槽宽度比例，用于判断滑动切换的页签数量 */
  static readonly SLOT_WIDTH_RATIO: number = 90;
}

/**
 * 指示器尺寸常量
 * 定义液态指示器的各种尺寸参数
 */
export class IndicatorConstants {
  /** 静止状态下指示器的基础宽度（vp） */
  static readonly BASE_WIDTH: number = 92;
  /** 静止状态下指示器的基础高度（vp） */
  static readonly BASE_HEIGHT: number = 54;
  /** 移动状态下指示器的基础宽度（vp） */
  static readonly MOVING_WIDTH: number = 110;
  /** 移动状态下指示器的基础高度（vp） */
  static readonly MOVING_HEIGHT: number = 74.5;
  /** 指示器内部图标尺寸（vp） */
  static readonly ICON_SIZE: number = 30;
  /** 指示器内部文本字体大小 */
  static readonly TEXT_SIZE: number = 9;
  /** 指示器外层容器宽度（vp） */
  static readonly CONTAINER_WIDTH: number = 80;
  /** 指示器外层容器高度（vp） */
  static readonly CONTAINER_HEIGHT: number = 80;
  /** 指示器圆角半径（vp） */
  static readonly BORDER_RADIUS: number = 30;
  /** 遮罩层宽度（vp） */
  static readonly MASK_WIDTH: number = 92;
  /** 遮罩层高度（vp） */
  static readonly MASK_HEIGHT: number = 54;
  /** 图标内边距（vp） */
  static readonly ICON_PADDING: number = 2;
  /** 文本内边距（vp） */
  static readonly TEXT_PADDING: number = 2;
  /** 图标圆角半径（vp） */
  static readonly ICON_BORDER_RADIUS: number = 12;
  /** 文本圆角半径（vp） */
  static readonly TEXT_BORDER_RADIUS: number = 15;
}

/**
 * 速度与形变常量
 * 定义液态效果的速度计算和形变参数
 */
export class VelocityConstants {
  /** 最大速度形变量（vp），限制指示器拉伸/收缩范围 */
  static readonly MAX_DEFORM: number = 45;
  /** 速度阈值（vp/帧），低于此值不产生形变效果 */
  static readonly THRESHOLD: number = 0.1;
  /** 速度归一化基准值（vp/帧），用于映射速度到0-1区间 */
  static readonly NORMALIZE_BASE: number = 25;
  /** 停顿判定时长（ms），超过该时长无显著速度视为停顿 */
  static readonly PAUSE_DURATION_MS: number = 80;
  /** 停顿判定速度阈值（vp/帧），低于此值视为静止 */
  static readonly PAUSE_THRESHOLD: number = 0.3;
  /** 锚点接近阈值（vp），距离小于该值视为靠近锚点 */
  static readonly ANCHOR_THRESHOLD: number = 28;
  /** 边界衰减系数，用于首尾页签拖动的阻力效果 */
  static readonly BOUNDARY_DECAY: number = 0.3;
  /** 速度平滑因子，用于减少速度波动让形变更流畅 */
  static readonly SMOOTHING_FACTOR: number = 0.3;
}

/**
 * 动画配置常量
 * 定义动画时长、延迟等时间参数
 */
export class AnimationConstants {
  /** 页签切换动画时长（ms） */
  static readonly SWITCH_DURATION: number = 300;
  /** 指示器复位动画时长（ms） */
  static readonly RESET_DURATION: number = 200;
  /** 锚点接近动画时长（ms） */
  static readonly PROXIMITY_DURATION: number = 150;
  /** 动画结束延迟时间（ms），确保动画完全执行 */
  static readonly SETTLE_DELAY: number = 310;
  /** 滑动时图标/文本的模糊程度 */
  static readonly BLUR_AMOUNT: number = 40;
  /** 图标切换动画时长（ms） */
  static readonly ICON_ANIMATION_DURATION: number = 400;
}

/**
 * 颜色常量
 * 定义TabBar和指示器的颜色配置
 */
export class ColorConstants {
  /** 遮罩颜色（透明），不影响底层高光效果 */
  static readonly MASK_COLOR: string = '#00ffffff';
  /** 指示器内部图标颜色（橙色） */
  static readonly ICON_COLOR: string = '#ffff923e';
  /** 指示器内部文本颜色（橙色） */
  static readonly TEXT_COLOR: string = '#ffff923e';
  /** TabBar浅色模式下的颜色 */
  static readonly LIGHT_COLOR: string = '#ff00eaff';
}

/**
 * Tab页签配置
 * 定义页签标题和图标资源
 */
export class TabConfig {
  /** 页签标题数组，对应4个页签的文本 */
  static readonly TITLES: string[] = ['首页', '二页', '三页', '四页'];
  /** 页签图标数组，对应4个页签的图标资源 */
  static readonly ICONS: Resource[] = [
    $r('sys.media.ohos_ic_public_remove'),
    $r('sys.media.ohos_ic_public_remove'),
    $r('sys.media.ohos_ic_public_remove'),
    $r('sys.media.ohos_ic_public_remove')
  ];
}