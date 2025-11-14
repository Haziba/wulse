import { Controller } from "@hotwired/stimulus";

export default class SidebarController extends Controller<HTMLElement> {
  static targets = ["sidebar", "overlay"];

  declare readonly sidebarTarget: HTMLElement;
  declare readonly overlayTarget: HTMLElement;

  private isOpen = false;

  connect(): void {
    if (window.innerWidth >= 900) {
      this.isOpen = true;
    }
  }

  toggle(event: Event): void {
    event.preventDefault();
    this.isOpen = !this.isOpen;
    this.updateSidebar();
  }

  close(event: Event): void {
    event.preventDefault();
    this.isOpen = false;
    this.updateSidebar();
  }

  private updateSidebar(): void {
    if (this.isOpen) {
      this.sidebarTarget.classList.remove("-translate-x-full");
      this.sidebarTarget.classList.add("translate-x-0");
      this.overlayTarget.classList.remove("hidden");
    } else {
      this.sidebarTarget.classList.remove("translate-x-0");
      this.sidebarTarget.classList.add("-translate-x-full");
      this.overlayTarget.classList.add("hidden");
    }
  }
}
