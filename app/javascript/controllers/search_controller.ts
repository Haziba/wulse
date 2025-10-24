import { Controller } from "@hotwired/stimulus";

export default class SearchController extends Controller<HTMLElement> {
  static values = {
    frame: String,
    debounce: { type: Number, default: 300 },
    preserveParams: { type: Boolean, default: true },
  };

  declare readonly frameValue: string;
  declare readonly debounceValue: number;
  declare readonly preserveParamsValue: boolean;

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
    }, this.debounceValue);
  }

  search(): void {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }

    const params = this.buildSearchParams();
    const url = `${window.location.pathname}?${params.toString()}`;

    Turbo.visit(url, { frame: this.frameValue, action: "advance" });
  }

  protected buildSearchParams(): URLSearchParams {
    const params = this.preserveParamsValue
      ? new URLSearchParams(window.location.search)
      : new URLSearchParams();

    this.element.querySelectorAll("input, select").forEach((element) => {
      const input = element as HTMLInputElement | HTMLSelectElement;
      const name = input.name || input.dataset.param;
      if (name) {
        params.set(name, input.value);
      }
    });

    return params;
  }
}
