import { Controller } from "@hotwired/stimulus";

export default class SidebarController extends Controller<HTMLElement> {
  static targets = ["sidebar", "overlay"];

  declare readonly sidebarTarget: HTMLElement;
  declare readonly overlayTarget: HTMLElement;

  private static readonly STORAGE_KEY = "sidebar_open";

  private get isOpen(): boolean {
    return localStorage.getItem(SidebarController.STORAGE_KEY) === "true";
  }

  private set isOpen(value: boolean) {
    localStorage.setItem(SidebarController.STORAGE_KEY, String(value));
  }

  connect(): void {
    this.updateSidebar();
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
