import { Controller } from "@hotwired/stimulus";

export default abstract class ReaderController<
  T extends HTMLElement = HTMLElement
> extends Controller<T> {
  static targets = [
    "loading",
    "container",
    "canvas",
    "documentContent",
    "pageIndicator",
    "toolbarPageInfo",
    "progressBar",
    "pageJumpInput",
    "prevButton",
    "nextButton",
    "zoomLevel",
    "sidebar",
    "outlineContainer",
  ];

  static values = {
    url: String,
    documentTitle: String,
  } as const;

  declare readonly loadingTarget: HTMLElement;
  declare readonly containerTarget: HTMLElement;
  declare readonly canvasTarget: HTMLCanvasElement;
  declare readonly documentContentTarget: HTMLElement;
  declare readonly pageIndicatorTarget: HTMLElement;
  declare readonly toolbarPageInfoTarget: HTMLElement;
  declare readonly progressBarTarget: HTMLElement;
  declare readonly pageJumpInputTarget: HTMLInputElement;
  declare readonly prevButtonTarget: HTMLButtonElement;
  declare readonly nextButtonTarget: HTMLButtonElement;
  declare readonly zoomLevelTarget: HTMLElement;
  declare readonly sidebarTarget: HTMLElement;
  declare readonly outlineContainerTarget: HTMLElement;

  declare readonly urlValue: string;
  declare readonly documentTitleValue: string;

  protected currentPage = 1;
  protected totalPages = 0;
  protected baseScale = 1.5;
  protected pageRendering = false;
  protected pageNumPending: number | null = null;
  protected ctx: CanvasRenderingContext2D | null = null;
  protected sidebarOpen = true;
  protected resizeObserver: ResizeObserver | null = null;

  protected readonly CONTENT_PADDING_X_PX = 32;
  protected readonly SIDEBAR_WIDTH_REM = 20;
  protected readonly SIDEBAR_TRANSITION_MS = 300;

  connect(): void {
    try {
      if (this.canvasTarget && this.canvasTarget.getContext) {
        this.ctx = this.canvasTarget.getContext("2d");
      }
    } catch (_) {}

    this.initSidebar();
    this.initResizeObserver();
    void this.initReader();
  }

  disconnect(): void {
    this.resizeObserver?.disconnect();
    this.resizeObserver = null;
  }

  protected abstract initReader(): Promise<void>;
  protected abstract renderPage(pageNum: number): Promise<void>;
  protected loadOutline(): Promise<void> | void {}

  protected initResizeObserver(): void {
    if (!this.documentContentTarget) return;
    this.resizeObserver = new ResizeObserver(() => {
      if (!this.pageRendering && this.totalPages > 0) {
        this.queueRenderPage(this.currentPage);
      }
    });
    this.resizeObserver.observe(this.documentContentTarget);
  }

  protected initSidebar(): void {
    if (window.innerWidth >= 1024) {
      this.sidebarOpen = true;
      this.applySidebarWidth(true);
    } else {
      this.sidebarOpen = false;
      this.applySidebarWidth(false);
    }
  }

  toggleSidebar(event: Event): void {
    event.preventDefault();
    this.sidebarOpen = !this.sidebarOpen;
    this.applySidebarWidth(this.sidebarOpen);
    window.setTimeout(
      () => this.queueRenderPage(this.currentPage),
      this.SIDEBAR_TRANSITION_MS
    );
  }

  closeSidebar(event: Event): void {
    event.preventDefault();
    if (!this.sidebarOpen) return;
    this.sidebarOpen = false;
    this.applySidebarWidth(false);
    window.setTimeout(
      () => this.queueRenderPage(this.currentPage),
      this.SIDEBAR_TRANSITION_MS
    );
  }

  protected applySidebarWidth(open: boolean): void {
    if (open) {
      this.sidebarTarget.classList.remove("-translate-x-full");
      this.sidebarTarget.classList.add("translate-x-0");
    } else {
      this.sidebarTarget.classList.remove("translate-x-0");
      this.sidebarTarget.classList.add("-translate-x-full");
    }
  }

  prevPage(event: Event): void {
    event.preventDefault();
    if (this.currentPage <= 1) return;
    this.currentPage -= 1;
    this.queueRenderPage(this.currentPage);
  }

  nextPage(event: Event): void {
    event.preventDefault();
    if (this.currentPage >= this.totalPages) return;
    this.currentPage += 1;
    this.queueRenderPage(this.currentPage);
  }

  gotoStart(event: Event): void {
    event.preventDefault();
    if (this.currentPage === 1) return;
    this.currentPage = 1;
    this.queueRenderPage(this.currentPage);
  }

  gotoEnd(event: Event): void {
    event.preventDefault();
    if (this.totalPages === 0) return;
    this.currentPage = this.totalPages;
    this.queueRenderPage(this.currentPage);
  }

  jumpToPage(event: Event): void {
    event.preventDefault();
    const raw = this.pageJumpInputTarget.value.trim();
    const num = Number.parseInt(raw, 10);
    if (Number.isFinite(num)) {
      const clamped = Math.min(Math.max(num, 1), Math.max(this.totalPages, 1));
      if (clamped !== this.currentPage) {
        this.currentPage = clamped;
        this.queueRenderPage(this.currentPage);
      }
    }
  }

  handlePageJumpKeypress(event: KeyboardEvent): void {
    if (event.key === "Enter") this.jumpToPage(event);
  }

  handleKeydown(event: KeyboardEvent): void {
    const target = event.target as HTMLElement | null;
    if (target && target.tagName === "INPUT") return;

    switch (event.key) {
      case "ArrowLeft":
      case "ArrowUp":
        if (event.metaKey || event.ctrlKey) break;
        event.preventDefault();
        this.prevPage(event);
        break;
      case "ArrowRight":
      case "ArrowDown":
        event.preventDefault();
        this.nextPage(event);
        break;
      case "Home":
        event.preventDefault();
        this.gotoStart(event);
        break;
      case "End":
        event.preventDefault();
        this.gotoEnd(event);
        break;
      default:
        break;
    }
  }

  toggleDarkMode(event: Event): void {
    event.preventDefault();
    this.documentContentTarget.classList.toggle("bg-gray-900");
    try {
      if (this.canvasTarget) this.canvasTarget.classList.toggle("invert");
    } catch (_) {}
  }

  toggleFullscreen(event: Event): void {
    event.preventDefault();
    if (!document.fullscreenElement) {
      void document.documentElement.requestFullscreen();
    } else {
      void document.exitFullscreen();
    }
  }

  protected updatePageInfo(): void {
    const page = this.currentPage;
    const total = this.totalPages;

    this.pageIndicatorTarget.textContent = `${page} / ${total}`;
    this.toolbarPageInfoTarget.textContent = `Page ${page} of ${total}`;

    const progress = total > 0 ? (page / total) * 100 : 0;
    this.progressBarTarget.style.width = `${progress.toFixed(2)}%`;

    this.pageJumpInputTarget.value = String(page);

    this.prevButtonTarget.disabled = page <= 1;
    this.nextButtonTarget.disabled = page >= total;
  }

  protected queueRenderPage(pageNum: number): void {
    if (this.pageRendering) {
      this.pageNumPending = pageNum;
    } else {
      void this.renderPage(pageNum);
    }
  }

  protected computeScaleFromNaturalWidth(naturalWidth: number): {
    scale: number;
    cssWidth: number;
  } {
    const containerWidth = Math.max(0, this.documentContentTarget.clientWidth);
    const usableWidth = Math.max(
      0,
      containerWidth - this.CONTENT_PADDING_X_PX * 2
    );
    const fitScale =
      usableWidth > 0 ? usableWidth / Math.max(1, naturalWidth) : 1;
    const scale = Math.min(this.baseScale, Math.max(0.2, fitScale));
    return { scale, cssWidth: Math.round(naturalWidth * scale) };
  }

  protected showError(message: string, error?: unknown): void {
    console.error(message, error);
    this.loadingTarget.innerHTML =
      '<i class="fas fa-exclamation-triangle text-4xl text-red-500 mb-4"></i>' +
      `<p class=\"text-gray-600\">${this.escapeHtml(message)}</p>`;
  }

  protected escapeHtml(text: string): string {
    const div = document.createElement("div");
    div.textContent = text ?? "";
    return div.innerHTML;
  }

  protected remToPx(rem: number): number {
    return (
      rem *
      parseFloat(getComputedStyle(document.documentElement).fontSize || "16")
    );
  }
}
