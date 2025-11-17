import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  declare readonly menuTarget: HTMLElement

  connect() {
    this.handleClickOutside = this.handleClickOutside.bind(this)
  }

  toggle(event: Event) {
    event.stopPropagation()
    const isHidden = this.menuTarget.classList.contains("hidden")

    if (isHidden) {
      this.menuTarget.classList.remove("hidden")
      // Add click listener to document after a short delay to prevent immediate closure
      setTimeout(() => {
        document.addEventListener("click", this.handleClickOutside)
      }, 0)
    } else {
      this.close()
    }
  }

  close() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this.handleClickOutside)
  }

  handleClickOutside(event: Event) {
    const target = event.target as HTMLElement

    // Close if clicking outside the menu
    if (!this.menuTarget.contains(target)) {
      this.close()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
  }
}
