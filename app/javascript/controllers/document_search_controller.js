import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input"];

  connect() {
    this.timeout = null;
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }

  searchDebounced() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }

    this.timeout = setTimeout(() => {
      this.search();
    }, 300);
  }

  search() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }

    const params = new URLSearchParams(window.location.search);
    params.set('search', this.inputTarget.value);

    const url = `${window.location.pathname}?${params.toString()}`;

    Turbo.visit(url, { frame: 'document_list', action: 'advance' });
  }
}
