import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this._onKeydown = this._onKeydown.bind(this)
    this.element.addEventListener("keydown", this._onKeydown)
  }

  disconnect() {
    this.element.removeEventListener("keydown", this._onKeydown)
  }

  _onKeydown(event) {
    if (event.key !== "Enter" || event.shiftKey) return
    event.preventDefault()
    this.element.form?.requestSubmit()
  }
}
