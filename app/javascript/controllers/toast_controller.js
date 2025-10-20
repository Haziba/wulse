import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    duration: { type: Number, default: 4000 },
  };

  connect() {
    this.timeout = setTimeout(() => {
      this.dismiss();
    }, this.durationValue);
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }

  dismiss() {
    this.element.classList.remove("animate-slide-up");
    this.element.classList.add("animate-slide-down");

    setTimeout(() => {
      this.element.remove();
    }, 300);
  }
}
