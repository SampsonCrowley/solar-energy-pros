import { Controller } from "stimuli/constants/controller"
import { MDCSelect } from '@material/select';
import { MDCRipple } from '@material/ripple';

export class SelectMenuController extends Controller {
  static keyName = "select-menu"
  static targets = [ "select", "item", "input", "text" ]

  async connected() {
    this.select = this.selectTarget
  }

  async disconnected(select, ripples) {
    if(!select) {
      select = this.select
      ripples = this.ripples
    }

    if(select) {
      for(let r = ripples.length; r > 0; r--) {
        await this.destroyRipple(ripples[r - 1])
      }
      await select.destroy()
    }
  }

  createRipple = (el) => {
    const ripple = new MDCRipple(el)
    this.ripples.push(ripple)
    return ripple
  }

  destroyRipple = async (ripple) => {
    await ripple.destroy()
    let idx
    while((idx = this.ripples.indexOf(ripple)) !== -1) {
      this.ripples.splice(idx, 1)
    }
  }

  onSelectChange = () => {
    console.debug(`Selected option at index ${this.select.selectedIndex} with value "${this.select.value}"`)
    // if(this.hasInputTarget) this.inputTarget.value = this.select.value
    // if(this.hasTextTarget) this.textTarget.innerText = this.select.value
  }

  get ripples () {
    return this._ripples || (this._ripples = [])
  }

  get select() {
    return this._select
  }

  set select(element) {
    if(this._select) this.disconnected(this._select, [...this.ripples])
    this._select = new MDCSelect(element)
    this.select.listen("MDCSelect:change", this.onSelectChange)
    this.itemTargets.forEach(this.createRipple)
    this.select.singleSelection = true
  }
}
