import { ZSTabs } from 'zstabs'
@Builder
function myBuilder(){
  Stack(){
    Text("Hello world")
  }
}

@Builder
function myBuilderT(){
  Stack(){
    Text("Hello worldwww")
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
              color:$r('app.color.start_window_background'),
              icon:$r('sys.media.ohos_ic_public_remove'),
              builder:wrapBuilder(myBuilder)
            },

            {
              title:"第一页",
              color:$r('app.color.start_window_background'),
              icon:$r('sys.media.ohos_ic_public_remove'),
              builder:wrapBuilder(myBuilderT)
            },

            {
              title:"第二页",
              color:$r('app.color.start_window_background'),
              icon:$r('sys.media.ohos_ic_public_remove'),
              builder:wrapBuilder(myBuilder)
            },
            {
              title:"第二页",
              color:$r('app.color.start_window_background'),
              icon:$r('sys.media.ohos_ic_public_remove'),
              builder:wrapBuilder(myBuilder)
            },

            {
              title:"第三页",
              color:$r('app.color.start_window_background'),
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