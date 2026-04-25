import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "picker"]
  static values = {
    isOwn: Boolean,
    content: String,
    editUrl: String,
    deleteUrl: String,
    reactionsUrl: String
  }

  connect() {
    this._onContextMenu = this._onContextMenu.bind(this)
    this._onDocMouseDown = this._onDocMouseDown.bind(this)
    this._onKey = this._onKey.bind(this)

    this.element.addEventListener("contextmenu", this._onContextMenu)

    // Build the menu from the template and attach it to body so
    // `position: fixed` is relative to the viewport, not a
    // backdrop-filtered ancestor.
    const frag = this.templateTarget.content.cloneNode(true)
    this._menu = frag.querySelector(".context-menu")
    this._menu.querySelectorAll("[data-menu-action]").forEach(btn => {
      btn.addEventListener("click", (e) => {
        e.preventDefault()
        const action = btn.dataset.menuAction
        if (typeof this[action] === "function") this[action](e)
      })
    })

    // The full picker lives inside the menu but starts hidden; the "+"
    // quick-reaction button toggles it.
    this._picker = this._menu.querySelector("emoji-picker")
    if (this._picker) {
      this._picker.addEventListener("emoji-click", (e) => {
        this._sendReaction(e.detail.unicode)
        this._close()
      })
    }

    document.body.appendChild(this._menu)
  }

  disconnect() {
    this.element.removeEventListener("contextmenu", this._onContextMenu)
    document.removeEventListener("mousedown", this._onDocMouseDown, true)
    document.removeEventListener("keydown", this._onKey)
    this._menu?.remove()
  }

  _onContextMenu(event) {
    event.preventDefault()
    const menu = this._menu
    if (this._picker) this._picker.hidden = true
    menu.hidden = false
    menu.style.left = `${event.clientX}px`
    menu.style.top = `${event.clientY}px`

    requestAnimationFrame(() => {
      const rect = menu.getBoundingClientRect()
      if (rect.right > window.innerWidth) {
        menu.style.left = `${Math.max(4, window.innerWidth - rect.width - 4)}px`
      }
      if (rect.bottom > window.innerHeight) {
        menu.style.top = `${Math.max(4, window.innerHeight - rect.height - 4)}px`
      }
    })

    // Defer so the mousedown that produced this contextmenu doesn't close us.
    setTimeout(() => {
      document.addEventListener("mousedown", this._onDocMouseDown, true)
      document.addEventListener("keydown", this._onKey)
    }, 0)
  }

  _close() {
    if (this._menu) this._menu.hidden = true
    if (this._picker) this._picker.hidden = true
    document.removeEventListener("mousedown", this._onDocMouseDown, true)
    document.removeEventListener("keydown", this._onKey)
  }

  _onDocMouseDown(event) {
    if (!this._menu.contains(event.target)) this._close()
  }

  _onKey(event) {
    if (event.key === "Escape") this._close()
  }

  // Stimulus action — also wired as a menu-action for quick buttons.
  // Reads the emoji from the clicked element's data-emoji attribute, so
  // the same handler serves both the quick-reaction buttons in the menu
  // and the reaction chips below the message.
  react(event) {
    const emoji = event.currentTarget?.dataset?.emoji
    if (!emoji) return
    this._sendReaction(emoji)
    this._close()
  }

  togglePicker() {
    if (!this._picker) return
    this._picker.hidden = !this._picker.hidden
  }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.contentValue)
    } catch (_) {
      // clipboard may be unavailable (http, permissions) — ignore
    }
    this._close()
  }

  async edit() {
    this._close()
    if (!this.editUrlValue) return
    const res = await fetch(this.editUrlValue, {
      headers: { Accept: "text/vnd.turbo-stream.html" }
    })
    if (res.ok) window.Turbo.renderStreamMessage(await res.text())
  }

  async delete() {
    this._close()
    if (!this.deleteUrlValue) return
    if (!confirm("Delete this message?")) return
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const res = await fetch(this.deleteUrlValue, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": token || "",
        Accept: "text/vnd.turbo-stream.html"
      }
    })
    if (res.ok) {
      const html = await res.text()
      if (html) window.Turbo.renderStreamMessage(html)
    }
  }

  async _sendReaction(emoji) {
    const url = this.reactionsUrlValue
    if (!url) return
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token || "",
        Accept: "application/json"
      },
      body: JSON.stringify({ reaction: { emoji } })
    })
  }
}
