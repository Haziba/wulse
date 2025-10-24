import { Controller } from "@hotwired/stimulus";

export default class extends Controller<HTMLElement> {
  static values = {
    duration: { type: Number, default: 4000 },
  };

  declare readonly durationValue: number;
  private timeout?: ReturnType<typeof setTimeout>;

  connect(): void {
    this.timeout = setTimeout(() => {
      this.dismiss();
    }, this.durationValue);
  }

  disconnect(): void {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }

  dismiss(): void {
    this.element.classList.remove("animate-slide-up");
    this.element.classList.add("animate-slide-down");

    setTimeout(() => {
      this.element.remove();
    }, 300);
  }
}
