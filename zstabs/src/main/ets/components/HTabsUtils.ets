import {
  ANCHOR_PROXIMITY_THRESHOLD,
  BAR_MOVING_HEIGHT,
  BAR_MOVING_WIDTH,
  MAX_VELOCITY_DEFORM,
  PAUSE_DURATION_MS,
  PAUSE_VELOCITY_THRESHOLD,
  SMOOTHING_FACTOR,
  VELOCITY_NORMALIZE_BASE,
  VELOCITY_THRESHOLD
} from './HTabsConstants';

export interface DeformationState {
  smoothedVelocity: number;
  initialDragDirection: number;
  lastActiveTimestamp: number;
  pauseDetected: boolean;
  velocityDeformationWidth: number;
  velocityDeformationHeight: number;
  animatedBarWidth: number;
  animatedBarHeight: number;
}

/**
 * 计算速度引起的形变效果
 */
export function calcVelocityDeformation(
  velocity: number,
  smoothedVelocity: number,
  initialDragDirection: number,
  lastActiveTimestamp: number,
  pauseDetected: boolean
): DeformationState {
  const absVelocity = Math.abs(velocity);
  const now = Date.now();
  let newSmoothedVelocity = smoothedVelocity * (1 - SMOOTHING_FACTOR) + velocity * SMOOTHING_FACTOR;
  let newInitialDragDirection = initialDragDirection;
  let newLastActiveTimestamp = lastActiveTimestamp;
  let newPauseDetected = pauseDetected;
  let velocityDeformationWidth = 0;
  let velocityDeformationHeight = 0;

  const absSmoothed = Math.abs(newSmoothedVelocity);

  if (absSmoothed >= PAUSE_VELOCITY_THRESHOLD) {
    newLastActiveTimestamp = now;
  }

  if (newLastActiveTimestamp > 0 && absSmoothed < PAUSE_VELOCITY_THRESHOLD) {
    if (now - newLastActiveTimestamp >= PAUSE_DURATION_MS) {
      newPauseDetected = true;
      newInitialDragDirection = 0;
      newLastActiveTimestamp = 0;
    }
  }

  if (absSmoothed < VELOCITY_THRESHOLD) {
    return {
      smoothedVelocity: newSmoothedVelocity,
      initialDragDirection: newInitialDragDirection,
      lastActiveTimestamp: newLastActiveTimestamp,
      pauseDetected: newPauseDetected,
      velocityDeformationWidth: 0,
      velocityDeformationHeight: 0,
      animatedBarWidth: BAR_MOVING_WIDTH,
      animatedBarHeight: BAR_MOVING_HEIGHT
    };
  }

  if (newInitialDragDirection === 0 || newPauseDetected) {
    newInitialDragDirection = newSmoothedVelocity > 0 ? 1 : -1;
    newPauseDetected = false;
  }

  const normalizedVelocity = Math.min(absSmoothed / VELOCITY_NORMALIZE_BASE, 1);
  const easedVelocity = Math.sqrt(normalizedVelocity);
  const deformAmount = easedVelocity * MAX_VELOCITY_DEFORM;
  const currentDirection = newSmoothedVelocity > 0 ? 1 : -1;
  const isSameDirection = currentDirection === newInitialDragDirection;

  if (isSameDirection) {
    velocityDeformationWidth = deformAmount;
    velocityDeformationHeight = -deformAmount * 0.5;
  } else {
    velocityDeformationWidth = -deformAmount * 0.5;
    velocityDeformationHeight = deformAmount;
  }

  return {
    smoothedVelocity: newSmoothedVelocity,
    initialDragDirection: newInitialDragDirection,
    lastActiveTimestamp: newLastActiveTimestamp,
    pauseDetected: newPauseDetected,
    velocityDeformationWidth,
    velocityDeformationHeight,
    animatedBarWidth: BAR_MOVING_WIDTH + velocityDeformationWidth,
    animatedBarHeight: BAR_MOVING_HEIGHT + velocityDeformationHeight
  };
}

export interface AnchorResult {
  nearestIndex: number;
  nearestDistance: number;
  isNearAnchor: boolean;
}

/**
 * 检测当前指示器位置是否靠近某个锚点
 */
export function findNearestAnchor(
  currentX: number,
  anchorPositions: number[]
): AnchorResult {
  let nearestDistance = Infinity;
  let nearestIndex = 0;

  for (let i = 0; i < anchorPositions.length; i++) {
    const distance = Math.abs(currentX - anchorPositions[i]);
    if (distance < nearestDistance) {
      nearestDistance = distance;
      nearestIndex = i;
    }
  }

  return {
    nearestIndex,
    nearestDistance,
    isNearAnchor: nearestDistance <= ANCHOR_PROXIMITY_THRESHOLD
  };
}

/**
 * 计算缩放后的锚点位置
 */
export function calcAnchorPositions(
  containerWidth: number,
  baseWidth: number,
  basePositions: number[]
): number[] {
  const scale = containerWidth / baseWidth;
  return basePositions.map(p => p * scale);
}

/**
 * 计算页签插槽宽度
 */
export function calcSlotWidth(containerWidth: number, baseWidth: number): number {
  return containerWidth * (90 / baseWidth);
}
