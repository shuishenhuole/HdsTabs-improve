export function showToast(msg:string,context:UIContext){
  context.getPromptAction().showToast({
    message:msg
  })
}