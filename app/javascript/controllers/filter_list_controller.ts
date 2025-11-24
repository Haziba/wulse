import { Controller } from "@hotwired/stimulus";
import { decompressFilters } from "../utils/filter_compression";

export default class extends Controller<HTMLElement> {
  static targets = ["item", "toggle"];
  static values = { limit: { type: Number, default: 3 } };

  declare readonly itemTargets: HTMLElement[];
  declare readonly toggleTarget: HTMLElement;
  declare readonly hasToggleTarget: boolean;
  declare readonly limitValue: number;

  private boundSyncCheckboxes!: () => void;

  connect(): void {
    this.updateVisibility();
    this.boundSyncCheckboxes = this.syncCheckboxesFromUrl.bind(this);
    document.addEventListener("turbo:render", this.boundSyncCheckboxes);
  }

  disconnect(): void {
    document.removeEventListener("turbo:render", this.boundSyncCheckboxes);
  }

  private async syncCheckboxesFromUrl(): Promise<void> {
    const url = new URL(window.location.href);
    const f = url.searchParams.get("f");

    const filters = f ? await decompressFilters(f) : {};

    const checkboxes = this.element.querySelectorAll<HTMLInputElement>(
      'input[type="checkbox"]'
    );

    checkboxes.forEach((checkbox) => {
      const name = checkbox.name.replace("[]", "");
      const filterValues = filters[name];

      if (!filterValues || filterValues.length === 0) {
        checkbox.checked = true;
      } else {
        checkbox.checked = filterValues.includes(checkbox.value);
      }
    });
  }

  updateVisibility(): void {
    const items = this.itemTargets;
    const totalItems = items.length;

    if (totalItems <= this.limitValue) {
      if (this.hasToggleTarget) {
        this.toggleTarget.classList.add("hidden");
      }
      return;
    }

    items.forEach((item, index) => {
      if (index >= this.limitValue) {
        item.classList.toggle("hidden", !this.isExpanded);
      }
    });

    if (this.hasToggleTarget) {
      this.toggleTarget.textContent = this.isExpanded
        ? "Show less"
        : "Show all";
      this.toggleTarget.classList.remove("hidden");
    }
  }

  toggle(): void {
    this.isExpanded = !this.isExpanded;
    this.updateVisibility();
  }

  selectOnly(event: Event): void {
    event.preventDefault();
    event.stopPropagation();
    const target = event.currentTarget as HTMLElement;
    const item = target.closest("[data-filter-list-target='item']");
    if (!item) return;

    const targetCheckbox = item.querySelector<HTMLInputElement>(
      'input[type="checkbox"]'
    );
    if (!targetCheckbox) return;

    const checkboxes = this.element.querySelectorAll<HTMLInputElement>(
      'input[type="checkbox"]'
    );
    checkboxes.forEach((checkbox) => {
      checkbox.checked = checkbox === targetCheckbox;
    });

    this.element.closest("form")?.requestSubmit();
  }

  selectAll(event: Event): void {
    event.preventDefault();

    const checkboxes = this.element.querySelectorAll<HTMLInputElement>(
      'input[type="checkbox"]'
    );
    checkboxes.forEach((checkbox) => {
      checkbox.checked = true;
    });

    this.element.closest("form")?.requestSubmit();
  }

  preventUncheckIfOnlyOption(event: Event): void {
    const checkbox = event.currentTarget as HTMLInputElement;
    const checkboxes = this.element.querySelectorAll<HTMLInputElement>(
      'input[type="checkbox"]'
    );

    if (checkboxes.length === 1 && !checkbox.checked) {
      checkbox.checked = true;
      event.preventDefault();
    }
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
