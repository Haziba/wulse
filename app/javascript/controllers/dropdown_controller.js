import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu"];

  connect() {
    // Close dropdown when clicking outside
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this);
  }

  toggle(event) {
    event.preventDefault();
    event.stopPropagation();

    this.menuTarget.classList.toggle("hidden");

    if (!this.menuTarget.classList.contains("hidden")) {
      // Add click listener to close when clicking outside
      document.addEventListener("click", this.closeOnClickOutside);
    } else {
      document.removeEventListener("click", this.closeOnClickOutside);
    }
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden");
      document.removeEventListener("click", this.closeOnClickOutside);
    }
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside);
  }
}
