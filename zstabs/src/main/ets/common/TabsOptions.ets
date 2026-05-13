export interface ZSTabsItem{
  title:string,
  icon:string,
  color:ResourceColor,
  selectColor?:ResourceColor,
  builder:WrappedBuilder<[]>
}

export interface ZSTabsOptions{
  tabItems:ZSTabsItem[],
  maskColor:ResourceColor
}

