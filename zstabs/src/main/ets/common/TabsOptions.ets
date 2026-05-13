export interface ZSTabsItem{
  title:string,
  icon:Resource,
  color:ResourceColor,
  selectColor?:ResourceColor,
  builder:WrappedBuilder<[]>
}

export interface ZSTabsOptions{
  tabItems:ZSTabsItem[],
  maskColor:ResourceColor,
  barBottomMargin?:number|Resource
}

