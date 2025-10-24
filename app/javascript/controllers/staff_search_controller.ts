import { Controller } from "@hotwired/stimulus";

export default class extends Controller<HTMLElement> {
  static targets = ["input", "select"];

  declare readonly inputTarget: HTMLInputElement;
  declare readonly selectTarget: HTMLSelectElement;
  private timeout: ReturnType<typeof setTimeout> | null = null;

  connect(): void {
    this.timeout = null;
  }

  disconnect(): void {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }

  searchDebounced(): void {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }

    this.timeout = setTimeout(() => {
      this.search();
    }, 300);
  }

  search(): void {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }

    const params = new URLSearchParams(window.location.search);
    params.set('search', this.inputTarget.value);
    params.set('status', this.selectTarget.value);

    const url = `${window.location.pathname}?${params.toString()}`;

    Turbo.visit(url, { frame: 'staff_list', action: 'advance' });
  }
}
