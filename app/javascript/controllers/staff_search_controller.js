import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "select"];

  connect() {
    console.log(this.inputTarget.value);
    console.log(this.selectTarget.value);
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
    params.set('status', this.selectTarget.value);

    const url = `${window.location.pathname}?${params.toString()}`;

    Turbo.visit(url, { frame: 'staff_list', action: 'advance' });
  }
}
