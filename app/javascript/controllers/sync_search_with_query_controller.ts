import { Controller } from "@hotwired/stimulus";

export default class extends Controller<HTMLInputElement> {
  private boundSyncFromUrl!: () => void;

  connect(): void {
    this.boundSyncFromUrl = this.syncFromUrl.bind(this);
    document.addEventListener("turbo:render", this.boundSyncFromUrl);
  }

  disconnect(): void {
    document.removeEventListener("turbo:render", this.boundSyncFromUrl);
  }

  private syncFromUrl(): void {
    const url = new URL(window.location.href);
    const q = url.searchParams.get("q") || "";
    this.element.value = q;
  }
}
