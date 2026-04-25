import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { autoDismiss: { type: Number, default: 5000 } }

  connect() {
    requestAnimationFrame(() => this.element.classList.add("flash--in"))
    if (this.autoDismissValue > 0) {
      this._timer = setTimeout(() => this.dismiss(), this.autoDismissValue)
    }
  }

  disconnect() {
    clearTimeout(this._timer)
  }

  dismiss() {
    clearTimeout(this._timer)
    this.element.classList.remove("flash--in")
    this.element.classList.add("flash--out")
    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
  }
}
