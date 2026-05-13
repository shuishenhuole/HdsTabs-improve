/**
 * 获取锚点位置
 * @param len tabContent的数量
 * @returns 锚点位置
 */
export function getBasePositions(len:number):number[]{
  if(len == 2){
    return [45,106]
  }
  else if(len === 3){
    return [8.5,122,241]
  }
  else if(len === 4){
    return [8.5,85,162.5,241]
  }
  else{
    throw Error("Invalid length")
  }
}

/**
 * @param len tabContent的数量
 * @returns容器宽度
 */
export function getBaseContainerWidth(len:number):number{
  if(len == 2){
    return 200
  }
  else if(len === 3){
    return 330
  }
  else if(len === 4){
    return 330
  }
  else{
    throw Error("Invalid length")
  }
}