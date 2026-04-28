import { Controller } from "@hotwired/stimulus"

// Loads older chat messages when the user scrolls to the top of #messages.
// A sentinel <div id="messages_top_sentinel" data-before-id="..."> sits at
// the top of the list; an IntersectionObserver fires when it comes into view,
// we fetch the prior page as a turbo_stream, and prepending preserves the
// user's visual position so the viewport doesn't jump.
export default class extends Controller {
  static values = { url: String }

  connect() {
    this._loading = false

    this._intersectionObserver = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) this._loadMore()
        }
      },
      { root: this.element, rootMargin: "200px 0px 0px 0px" }
    )

    this._observeSentinel()

    // The sentinel gets replaced after each successful load, so re-attach the
    // IntersectionObserver whenever #messages' direct children change.
    this._mutationObserver = new MutationObserver(() => this._observeSentinel())
    this._mutationObserver.observe(this.element, { childList: true })
  }

  disconnect() {
    this._intersectionObserver?.disconnect()
    this._mutationObserver?.disconnect()
  }

  _observeSentinel() {
    const sentinel = this.element.querySelector("#messages_top_sentinel")
    if (sentinel === this._currentSentinel) return
    if (this._currentSentinel) this._intersectionObserver.unobserve(this._currentSentinel)
    this._currentSentinel = sentinel
    if (sentinel) this._intersectionObserver.observe(sentinel)
  }

  async _loadMore() {
    if (this._loading) return
    const sentinel = this.element.querySelector("#messages_top_sentinel")
    const beforeId = sentinel?.dataset.beforeId
    if (!beforeId) return
    this._loading = true

    // Capture distance from bottom so we can restore the same visual position
    // after older messages are prepended above the user's current view.
    const distanceFromBottom = this.element.scrollHeight - this.element.scrollTop

    try {
      const url = `${this.urlValue}?before_id=${encodeURIComponent(beforeId)}`
      const response = await fetch(url, {
        headers: { Accept: "text/vnd.turbo-stream.html" },
        credentials: "same-origin"
      })
      if (!response.ok) return

      const html = await response.text()
      window.Turbo.renderStreamMessage(html)

      this.element.scrollTop = this.element.scrollHeight - distanceFromBottom
    } finally {
      this._loading = false
    }
  }
}
