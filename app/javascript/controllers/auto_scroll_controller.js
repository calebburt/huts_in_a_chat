import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { nearBottom: { type: Number, default: 120 } }

  connect() {
    // Track whether the user was near the bottom *before* the next mutation,
    // since appending a message grows scrollHeight and would otherwise make
    // the post-mutation check always read as "far from bottom".
    this.stickToBottom = true

    this._onScroll = () => { this.stickToBottom = this._isNearBottom() }
    // Image attachments finish loading after insertion and grow scrollHeight.
    this._onLoad = (event) => {
      if (event.target.tagName === "IMG" && this.stickToBottom) this._scrollToBottom()
    }

    this.element.addEventListener("scroll", this._onScroll)
    this.element.addEventListener("load", this._onLoad, true)

    this._scrollToBottom()
    requestAnimationFrame(() => this._scrollToBottom())

    this._observer = new MutationObserver(() => {
      if (this.stickToBottom) this._scrollToBottom()
    })
    this._observer.observe(this.element, { childList: true })
  }

  disconnect() {
    this.element.removeEventListener("scroll", this._onScroll)
    this.element.removeEventListener("load", this._onLoad, true)
    this._observer?.disconnect()
  }

  _scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }

  _isNearBottom() {
    return this.element.scrollHeight - this.element.scrollTop - this.element.clientHeight < this.nearBottomValue
  }
}
