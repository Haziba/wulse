import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.element.showModal();

    this.element.addEventListener("click", (e) => {
      if (e.target === this.element) {
        this.close();
      }
    });
  }

  close() {
    this.element.close();
    this.element.remove();
  }

  submitEnd(e) {
    if (e.detail.success) {
      this.close();
    }
  }
}
