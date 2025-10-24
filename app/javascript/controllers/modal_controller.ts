import { Controller } from "@hotwired/stimulus";

export default class extends Controller<HTMLDialogElement> {
  connect(): void {
    this.element.showModal();

    this.element.addEventListener("click", (e: MouseEvent) => {
      if (e.target === this.element) {
        this.close();
      }
    });
  }

  close(): void {
    this.element.close();
    this.element.remove();
  }

  submitEnd(e: CustomEvent): void {
    if (e.detail.success) {
      this.close();
    }
  }
}
