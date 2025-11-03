import { Controller } from "@hotwired/stimulus";
import * as pdfjsLib from "pdfjs-dist";

export default class extends Controller<HTMLElement> {
  static targets = [
    "loading",
    "pdfContainer",
    "canvas",
    "documentContent",
    "pageIndicator",
    "toolbarPageInfo",
    "progressBar",
    "pageJumpInput",
    "prevButton",
    "nextButton",
    "sidebar",
    "outlineContainer",
  ];

  static values = {
    url: String,
    documentTitle: String,
  };

  declare readonly loadingTarget: HTMLElement;
  declare readonly pdfContainerTarget: HTMLElement;
  declare readonly canvasTarget: HTMLCanvasElement;
  declare readonly documentContentTarget: HTMLElement;
  declare readonly pageIndicatorTarget: HTMLElement;
  declare readonly toolbarPageInfoTarget: HTMLElement;
  declare readonly progressBarTarget: HTMLElement;
  declare readonly pageJumpInputTarget: HTMLInputElement;
  declare readonly prevButtonTarget: HTMLButtonElement;
  declare readonly nextButtonTarget: HTMLButtonElement;
  declare readonly sidebarTarget: HTMLElement;
  declare readonly outlineContainerTarget: HTMLElement;

  declare readonly urlValue: string;
  declare readonly documentTitleValue: string;

  private pdfDoc: any = null;
  private currentPage: number = 1;
  private totalPages: number = 0;
  private scale: number = 1.5;
  private baseScale: number = 1.5;
  private pageRendering: boolean = false;
  private pageNumPending: number | null = null;
  private ctx: CanvasRenderingContext2D | null = null;
  private sidebarOpen: boolean = true;

  connect(): void {
    this.ctx = this.canvasTarget.getContext("2d");
    this.initializePDF();
    this.initializeSidebar();
    this.setupResizeHandler();
  }

  disconnect(): void {
    window.removeEventListener("resize", this.handleResize);
  }

  private handleResize = (): void => {
    if (this.pdfDoc && !this.pageRendering) {
      this.queueRenderPage(this.currentPage);
    }
  };

  private setupResizeHandler(): void {
    window.addEventListener("resize", this.handleResize);
  }

  private async initializePDF(): Promise<void> {
    try {
      const version = "5.4.296";
      pdfjsLib.GlobalWorkerOptions.workerSrc = `https://unpkg.com/pdfjs-dist@${version}/build/pdf.worker.min.mjs`;

      const loadingTask = pdfjsLib.getDocument(this.urlValue);
      this.pdfDoc = await loadingTask.promise;
      this.totalPages = this.pdfDoc.numPages;

      this.pageJumpInputTarget.max = this.totalPages.toString();

      await this.renderPage(this.currentPage);

      this.loadOutline();
    } catch (error) {
      console.error("Error loading PDF:", error);
      this.loadingTarget.innerHTML =
        '<i class="fas fa-exclamation-triangle text-4xl text-red-500 mb-4"></i><p class="text-gray-600">Error loading PDF</p>';
    }
  }

  private async renderPage(num: number): Promise<void> {
    this.pageRendering = true;

    const page = await this.pdfDoc.getPage(num);

    // Calculate responsive scale based on container width
    const containerWidth = this.documentContentTarget.clientWidth;
    const pageViewport = page.getViewport({ scale: 1 });
    const maxWidth = containerWidth - 64; // Account for padding (32px on each side)
    const responsiveScale = Math.min(
      this.baseScale,
      maxWidth / pageViewport.width
    );

    const viewport = page.getViewport({ scale: responsiveScale });

    this.canvasTarget.height = viewport.height;
    this.canvasTarget.width = viewport.width;

    const renderContext = {
      canvasContext: this.ctx,
      viewport: viewport,
    };

    await page.render(renderContext).promise;

    this.pageRendering = false;
    this.loadingTarget.classList.add("hidden");
    this.pdfContainerTarget.classList.remove("hidden");

    this.documentContentTarget.scrollTop = 0;

    if (this.pageNumPending !== null) {
      this.renderPage(this.pageNumPending);
      this.pageNumPending = null;
    }

    this.updatePageInfo();
  }

  private queueRenderPage(num: number): void {
    if (this.pageRendering) {
      this.pageNumPending = num;
    } else {
      this.renderPage(num);
    }
  }

  private updatePageInfo(): void {
    this.pageIndicatorTarget.textContent = `${this.currentPage} / ${this.totalPages}`;
    this.toolbarPageInfoTarget.textContent = `Page ${this.currentPage} of ${this.totalPages}`;

    const progress = (this.currentPage / this.totalPages) * 100;
    this.progressBarTarget.style.width = progress + "%";

    this.pageJumpInputTarget.value = this.currentPage.toString();

    this.prevButtonTarget.disabled = this.currentPage <= 1;
    this.nextButtonTarget.disabled = this.currentPage >= this.totalPages;
  }

  prevPage(event: Event): void {
    event.preventDefault();
    if (this.currentPage <= 1) return;
    this.currentPage--;
    this.queueRenderPage(this.currentPage);
  }

  nextPage(event: Event): void {
    event.preventDefault();
    if (this.currentPage >= this.totalPages) return;
    this.currentPage++;
    this.queueRenderPage(this.currentPage);
  }

  gotoStart(event: Event): void {
    event.preventDefault();
    this.currentPage = 1;
    this.queueRenderPage(this.currentPage);
  }

  gotoEnd(event: Event): void {
    event.preventDefault();
    this.currentPage = this.totalPages;
    this.queueRenderPage(this.currentPage);
  }

  jumpToPage(event: Event): void {
    event.preventDefault();
    const pageNum = parseInt(this.pageJumpInputTarget.value);
    if (pageNum >= 1 && pageNum <= this.totalPages) {
      this.currentPage = pageNum;
      this.queueRenderPage(this.currentPage);
    }
  }

  handlePageJumpKeypress(event: KeyboardEvent): void {
    if (event.key === "Enter") {
      this.jumpToPage(event);
    }
  }

  toggleDarkMode(event: Event): void {
    event.preventDefault();
    this.documentContentTarget.classList.toggle("bg-gray-900");
    this.canvasTarget.classList.toggle("invert");
  }

  toggleFullscreen(event: Event): void {
    event.preventDefault();
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen();
    } else {
      document.exitFullscreen();
    }
  }

  private initializeSidebar(): void {
    if (window.innerWidth >= 1024) {
      this.sidebarOpen = true;
      this.sidebarTarget.style.transition = "none";
      this.sidebarTarget.style.width = "20rem";
      this.sidebarTarget.style.minWidth = "20rem";
      this.sidebarTarget.offsetHeight;
      this.sidebarTarget.style.transition = "";
    } else {
      this.sidebarOpen = false;
    }
  }

  toggleSidebar(event: Event): void {
    event.preventDefault();
    this.sidebarOpen = !this.sidebarOpen;
    if (this.sidebarOpen) {
      this.sidebarTarget.style.width = "20rem";
      this.sidebarTarget.style.minWidth = "20rem";
    } else {
      this.sidebarTarget.style.width = "0";
      this.sidebarTarget.style.minWidth = "0";
    }

    // Re-render after sidebar transition completes
    setTimeout(() => {
      if (this.pdfDoc) {
        this.queueRenderPage(this.currentPage);
      }
    }, 300);
  }

  closeSidebar(event: Event): void {
    event.preventDefault();
    this.sidebarOpen = false;
    this.sidebarTarget.style.width = "0";
    this.sidebarTarget.style.minWidth = "0";

    // Re-render after sidebar transition completes
    setTimeout(() => {
      if (this.pdfDoc) {
        this.queueRenderPage(this.currentPage);
      }
    }, 300);
  }

  private async loadOutline(): Promise<void> {
    const outline = await this.pdfDoc.getOutline();

    if (outline && outline.length > 0) {
      this.outlineContainerTarget.innerHTML = "";
      this.renderOutlineItems(outline, this.outlineContainerTarget, 0);
    } else {
      this.outlineContainerTarget.innerHTML =
        '<div class="text-sm text-gray-500 text-center py-4">No table of contents available</div>';
    }
  }

  private renderOutlineItems(
    items: any[],
    container: HTMLElement,
    level: number
  ): void {
    items.forEach((item) => {
      const div = document.createElement("div");
      div.className = "p-3 rounded-lg hover:bg-gray-100 cursor-pointer";
      if (level > 0) {
        div.style.marginLeft = level * 12 + "px";
      }

      div.innerHTML = `
        <div class="flex items-center justify-between">
          <span class="text-sm font-medium text-gray-900">${this.escapeHtml(
            item.title
          )}</span>
        </div>
      `;

      div.addEventListener("click", async () => {
        const dest = await this.pdfDoc.getDestination(item.dest);
        if (dest) {
          const pageIndex = await this.pdfDoc.getPageIndex(dest[0]);
          this.currentPage = pageIndex + 1;
          this.queueRenderPage(this.currentPage);
        }
      });

      container.appendChild(div);

      if (item.items && item.items.length > 0) {
        this.renderOutlineItems(item.items, container, level + 1);
      }
    });
  }

  private escapeHtml(text: string): string {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }

  handleKeydown(event: KeyboardEvent): void {
    if ((event.target as HTMLElement).tagName === "INPUT") return;

    if (event.key === "ArrowLeft" || event.key === "ArrowUp") {
      event.preventDefault();
      this.prevPage(event);
    } else if (event.key === "ArrowRight" || event.key === "ArrowDown") {
      event.preventDefault();
      this.nextPage(event);
    } else if (event.key === "Home") {
      event.preventDefault();
      this.gotoStart(event);
    } else if (event.key === "End") {
      event.preventDefault();
      this.gotoEnd(event);
    }
  }
}
