import { Controller } from "@hotwired/stimulus";

export default class extends Controller<HTMLElement> {
  static targets = ["item", "toggle"];
  static values = { limit: { type: Number, default: 3 } };

  declare readonly itemTargets: HTMLElement[];
  declare readonly toggleTarget: HTMLElement;
  declare readonly hasToggleTarget: boolean;
  declare readonly limitValue: number;

  connect(): void {
    this.updateVisibility();
  }

  updateVisibility(): void {
    const items = this.itemTargets;
    const totalItems = items.length;

    if (totalItems <= this.limitValue) {
      // Hide toggle if there aren't enough items
      if (this.hasToggleTarget) {
        this.toggleTarget.classList.add("hidden");
      }
      return;
    }

    // Show/hide items based on expanded state
    items.forEach((item, index) => {
      if (index >= this.limitValue) {
        item.classList.toggle("hidden", !this.isExpanded);
      }
    });

    // Update toggle text
    if (this.hasToggleTarget) {
      this.toggleTarget.textContent = this.isExpanded ? "Show less" : "Show all";
      this.toggleTarget.classList.remove("hidden");
    }
  }

  toggle(): void {
    this.isExpanded = !this.isExpanded;
    this.updateVisibility();
  }

  get isExpanded(): boolean {
    const key = this.storageKey;
    if (!key) return false;
    return localStorage.getItem(key) === "true";
  }

  set isExpanded(value: boolean) {
    const key = this.storageKey;
    if (!key) return;
    localStorage.setItem(key, value.toString());
  }

  get storageKey(): string | null {
    const id = this.element.id;
    return id ? `filter-expanded-${id}` : null;
  }
}
