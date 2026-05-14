// ==================== 指示器尺寸常量 ====================

/** 指示器静止时宽度（vp） */
export const BAR_RESTING_WIDTH = 92;
/** 指示器静止时高度（vp） */
export const BAR_RESTING_HEIGHT = 54;

/** 指示器移动时基础宽度（vp），形变在此基础上叠加 */
export const BAR_MOVING_WIDTH = 110;
/** 指示器移动时基础高度（vp） */
export const BAR_MOVING_HEIGHT = 74.5;

/** 指示器圆角半径（vp） */
export const BAR_BORDER_RADIUS = 30;

// ==================== 布局常量 ====================

/** TabBar 高度（vp） */
export const TAB_BAR_HEIGHT = 59;
/** 指示器容器固定宽度（vp） */
export const INDICATOR_CONTAINER_WIDTH = 330;

// ==================== 速度形变参数 ====================

/** 最大速度形变量（vp），限制拉伸/收缩范围 */
export const MAX_VELOCITY_DEFORM = 45;
/** 速度阈值（vp/帧），低于此值不产生形变 */
export const VELOCITY_THRESHOLD = 0.1;
/** 速度归一化基准值（vp/帧），将实际速度映射到 0-1 区间 */
export const VELOCITY_NORMALIZE_BASE = 25;
/** 速度平滑因子（0-1），值越小平滑效果越强 */
export const SMOOTHING_FACTOR = 0.3;

// ==================== 停顿检测参数 ====================

/** 停顿判定时长（ms），超过该时长无显著速度则视为停顿 */
export const PAUSE_DURATION_MS = 80;
/** 停顿判定的速度阈值（vp/帧），低于此值视为静止 */
export const PAUSE_VELOCITY_THRESHOLD = 0.3;

// ==================== 交互阈值 ====================

/** 锚点接近阈值（vp），距离小于此值时取消图标/文本模糊 */
export const ANCHOR_PROXIMITY_THRESHOLD = 28;

// ==================== 动画时长（ms） ====================

/** 页签切换动画时长 */
export const ANIM_DURATION_SWITCH = 300;
/** 拖动回弹动画时长 */
export const ANIM_DURATION_RESET = 200;
/** 靠近锚点过渡动画时长 */
export const ANIM_DURATION_NEAR_ANCHOR = 150;
/** 图标切换动画时长 */
export const ANIM_DURATION_ICON = 400;

// ==================== 手势参数 ====================

/** 边界拖动衰减系数（首尾页签越界时的阻尼感） */
export const EDGE_DRAG_DAMPING = 0.3;

// ==================== 视觉效果 ====================

/** 滑动时图标/文本模糊强度 */
export const BLUR_AMOUNT = 20;
