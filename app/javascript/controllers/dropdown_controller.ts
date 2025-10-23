import { Controller } from "@hotwired/stimulus";

export default class DropdownController extends Controller<HTMLElement> {
  static targets = ["menu"];

  declare readonly menuTarget: HTMLElement;
  declare readonly hasMenuTarget: boolean;

  connect(): void {
    // Close dropdown when clicking outside
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this);
  }

  toggle(event: Event): void {
    event.preventDefault();
    event.stopPropagation();

    this.menuTarget.classList.toggle("hidden");

    if (!this.menuTarget.classList.contains("hidden")) {
      // Add click listener to close when clicking outside
      document.addEventListener("click", this.closeOnClickOutside);
    } else {
      document.removeEventListener("click", this.closeOnClickOutside);
    }
  }

  closeOnClickOutside(event: Event): void {
    const target = event.target as Node;
    if (!this.element.contains(target)) {
      this.menuTarget.classList.add("hidden");
      document.removeEventListener("click", this.closeOnClickOutside);
    }
  }

  disconnect(): void {
    document.removeEventListener("click", this.closeOnClickOutside);
  }
}
