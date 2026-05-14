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
