import { ZSTabs } from '@shuishenhuole/zstabs'

@Builder
function HomeBuilder(){
  Stack(){
    Text("Hello world HomeBuilder")
  }
}

@Builder
function PageOneBuilder(){
  Stack(){
    Text("Hello world PageOneBuilder")
  }
}

@Builder
function PageTwoBuilder(){
  Stack(){
    Text("Hello world PageTwoBuilder")
  }
}

@Builder
function PageThreeBuilder(){
  Stack(){
    Text("Hello world PageThreeBuilder")
  }
}
@Entry
@ComponentV2
struct Index {
  @Local Index:number = 0
  build() {
    Column(){
      ZSTabs({
        currentIndex:this.Index!!,
        tabsOption:{
          tabItems:[
            {
              title:"首页",
              color:$r('sys.color.icon'),
              selectColor:$r('sys.color.warning'),
              icon:$r('sys.symbol.message'),
              builder:wrapBuilder(HomeBuilder),
            },
            {
              title:"第一页",
              color:$r('sys.color.icon'),
              selectColor:$r('sys.color.warning'),
              icon:$r('sys.media.ohos_ic_public_remove'),
              builder:wrapBuilder(PageOneBuilder),
            },
            {
              title:"第二页",
              color:$r('sys.color.icon'),
              selectColor:$r('sys.color.warning'),
              icon:$r('sys.media.ohos_ic_public_remove'),
              builder:wrapBuilder(PageTwoBuilder)
            },
            {
              title:"第三页",
              color:$r('sys.color.icon'),
              selectColor:$r('sys.color.warning'),
              icon:$r('sys.media.ohos_ic_public_remove'),
              builder:wrapBuilder(PageThreeBuilder)
            },
          ],
          maskColor:"#8d5ce7"
        }
      })
    }
  }
}