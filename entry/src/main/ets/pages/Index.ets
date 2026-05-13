import { ZSTabs } from 'zstabs'
@Builder
function myBuilder(){
  Stack(){
    Text("Hello world")
  }
}

@Entry
@ComponentV2
struct Index {
  build() {
    Column(){
      ZSTabs({
        tabsOption:{
          tabItems:[
            {
              title:"首页",
              color:$r('sys.color.icon'),
              selectColor:$r('sys.color.warning'),
              icon:$r('sys.media.ohos_ic_public_remove'),
              builder:wrapBuilder(myBuilder),
            },
            {
              title:"第一页",
              icon:$r('sys.media.ohos_ic_public_remove'),
              builder:wrapBuilder(myBuilder),
              color:$r('sys.color.icon'),
              selectColor:$r('sys.color.warning'),
            },
            {
              title:"第二页",
              color:$r('sys.color.icon'),
              selectColor:$r('sys.color.warning'),
              icon:$r('sys.media.ohos_ic_public_remove'),
              builder:wrapBuilder(myBuilder)
            },
            {
              title:"第三页",
              color:$r('sys.color.icon'),
              selectColor:$r('sys.color.warning'),
              icon:$r('sys.media.ohos_ic_public_remove'),
              builder:wrapBuilder(myBuilder)
            },
          ],
          maskColor:"#8d5ce7"
        }
      })
    }
  }
}