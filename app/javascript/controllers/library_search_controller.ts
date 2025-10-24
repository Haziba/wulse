import { Controller } from "@hotwired/stimulus";

export default class extends Controller<HTMLElement> {
  static targets = ["input"];

  declare readonly inputTarget: HTMLInputElement;
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

    const params = new URLSearchParams();
    params.set('search', this.inputTarget.value);

    const url = `${window.location.pathname}?${params.toString()}`;

    Turbo.visit(url, { frame: 'library_list', action: 'advance' });
  }
}
