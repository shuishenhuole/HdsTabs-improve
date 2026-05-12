/**
 * 锚点计算器
 * 提供指示器锚点位置计算相关的方法
 */
export class AnchorCalculator {
  /**
   * 计算实时锚点位置数组
   * 基于当前容器宽度与基准宽度的比例，对基础锚点位置进行缩放
   * @param containerWidth 当前容器宽度
   * @param basePositions 基础锚点位置数组
   * @param baseContainerWidth 基准容器宽度
   * @returns 缩放后的锚点位置数组
   */
  static getAnchorPositions(containerWidth: number, basePositions: number[], baseContainerWidth: number): number[] {
    const scale = containerWidth / baseContainerWidth;
    return basePositions.map(p => p * scale);
  }

  /**
   * 获取指定索引的锚点位置
   * @param positions 锚点位置数组
   * @param index 目标索引
   * @returns 锚点X坐标
   */
  static getAnchorPosition(positions: number[], index: number): number {
    return positions[index];
  }

  /**
   * 计算页签插槽宽度
   * 用于判断滑动切换的页签数量
   * @param containerWidth 容器宽度
   * @param slotWidthRatio 插槽宽度比例
   * @param baseContainerWidth 基准容器宽度
   * @returns 插槽宽度
   */
  static getSlotWidth(containerWidth: number, slotWidthRatio: number, baseContainerWidth: number): number {
    return containerWidth * (slotWidthRatio / baseContainerWidth);
  }

  /**
   * 检测是否靠近锚点并返回最近锚点信息
   * @param currentX 当前X坐标
   * @param positions 锚点位置数组
   * @param currentIndex 当前索引
   * @param threshold 阈值距离
   * @returns { isNear: boolean, nearestIndex: number, nearestDistance: number }
   */
  static checkNearAnchor(
    currentX: number,
    positions: number[],
    currentIndex: number,
    threshold: number
  ): { isNear: boolean; nearestIndex: number; nearestDistance: number } {
    let nearestDistance = Infinity;
    let nearestIndex = currentIndex;

    for (let i = 0; i < positions.length; i++) {
      const distance = Math.abs(currentX - positions[i]);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }

    return {
      isNear: nearestDistance <= threshold,
      nearestIndex,
      nearestDistance
    };
  }
}