import { Controller } from "@hotwired/stimulus";

export default class extends Controller<HTMLElement> {
  static targets = ["item", "toggle", "checkbox"];
  static values = { limit: { type: Number, default: 3 } };

  declare readonly itemTargets: HTMLElement[];
  declare readonly toggleTarget: HTMLElement;
  declare readonly hasToggleTarget: boolean;
  declare readonly checkboxTargets: HTMLInputElement[];
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

  selectAll(event: Event): void {
    event.preventDefault();
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = true;
    });
  }

  selectNone(event: Event): void {
    event.preventDefault();
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = false;
    });
  }

  get isExpanded(): boolean {
    return this.data.get("expanded") === "true";
  }

  set isExpanded(value: boolean) {
    this.data.set("expanded", value.toString());
  }
}
