import { ZSTabs } from 'zstabs'

@Entry
@ComponentV2
struct Index {
  build() {
    Column(){
      ZSTabs({
        tabsOption:{
          tabItems:[],
          maskColor:"#8d5ce7"
        }
      })
    }
  }
}