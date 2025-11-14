import ReaderController from "./reader_controller";
import ePub from "epubjs";

type Book = any;
type Rendition = any;

export default class EpubReaderController extends ReaderController {
  private book: Book | null = null;
  private rendition: Rendition | null = null;
  private lastRelocatedPage: number | null = null;

  async connect(): Promise<void> {
    try {
      if (this.canvasTarget && this.canvasTarget.getContext) {
        this.ctx = this.canvasTarget.getContext("2d");
      }
    } catch (_) {}

    this.initSidebar();
    await this.initReader();
    this.initResizeObserver();
  }

  protected initResizeObserver(): void {
    if (!this.documentContentTarget) return;

    let resizeTimeout: number | null = null;
    this.resizeObserver = new ResizeObserver(() => {
      if (resizeTimeout) {
        window.clearTimeout(resizeTimeout);
      }
      resizeTimeout = window.setTimeout(() => {
        if (this.rendition && this.containerTarget) {
          const newWidth = this.containerTarget.clientWidth;
          const newHeight = this.containerTarget.clientHeight;
          this.rendition.resize(newWidth, newHeight);
        }
      }, 150);
    });
    this.resizeObserver.observe(this.documentContentTarget);
  }

  protected async initReader(): Promise<void> {
    try {
      this.book = ePub(this.urlValue);
      await this.book.ready;

      const containerWidth = this.containerTarget.clientWidth;
      const containerHeight = this.containerTarget.clientHeight;

      this.rendition = this.book.renderTo(this.containerTarget, {
        width: containerWidth,
        height: containerHeight,
        spread: "none",
        flow: "paginated",
      });

      await this.rendition.display();

      await this.book.loaded.navigation;

      const locations = await this.book.locations.generate(1600);
      this.totalPages = locations.length;
      this.pageJumpInputTarget.max = String(this.totalPages);

      this.rendition.on("relocated", (location: any) => {
        const currentLocation = this.book.locations.locationFromCfi(location.start.cfi);
        if (currentLocation != null) {
          const newPage = currentLocation + 1;

          if (this.lastRelocatedPage !== newPage) {
            this.lastRelocatedPage = newPage;
            this.currentPage = newPage;
            this.updatePageInfo();
          }
        }
      });

      this.currentPage = 1;
      this.lastRelocatedPage = 1;
      this.updatePageInfo();

      this.loadingTarget.classList.add("hidden");

      void this.loadOutline();
    } catch (error) {
      console.error("Error loading EPUB:", error);
      this.showError("Error loading EPUB", error);
    }
  }

  protected async renderPage(pageNum: number): Promise<void> {
    if (!this.book || !this.rendition) return;

    try {
      const cfi = this.book.locations.cfiFromLocation(pageNum - 1);
      if (cfi) {
        this.currentPage = pageNum;
        this.lastRelocatedPage = pageNum;
        await this.rendition.display(cfi);
        this.updatePageInfo();
      }
    } catch (error) {
      this.showError("Error rendering page", error);
    }
  }

  protected async loadOutline(): Promise<void> {
    try {
      if (!this.book) return;

      const navigation = await this.book.loaded.navigation;
      const toc = navigation.toc;

      if (toc && toc.length > 0) {
        this.outlineContainerTarget.innerHTML = "";
        this.renderOutlineItems(toc, this.outlineContainerTarget, 0);
      } else {
        this.outlineContainerTarget.innerHTML =
          '<div class="text-sm text-gray-500 text-center py-4">No table of contents available</div>';
      }
    } catch (error) {
      this.showError("Error loading outline", error);
    }
  }

  private renderOutlineItems(
    items: any[],
    container: HTMLElement,
    level: number
  ): void {
    for (const item of items) {
      const row = document.createElement("div");
      row.className = "p-3 rounded-lg hover:bg-gray-100 cursor-pointer";
      if (level > 0) row.style.marginLeft = `${level * 12}px`;

      row.innerHTML = `
        <div class="flex items-center justify-between">
          <span class="text-sm font-medium text-gray-900">${this.escapeHtml(
            item.label || "Untitled"
          )}</span>
        </div>
      `;

      row.addEventListener("click", async () => {
        try {
          if (!this.rendition || !item.href) return;
          await this.rendition.display(item.href);
        } catch (err) {
          this.showError("Unable to navigate to outline destination", err);
        }
      });

      container.appendChild(row);

      if (item.subitems && item.subitems.length) {
        this.renderOutlineItems(item.subitems, container, level + 1);
      }
    }
  }

  // Override sidebar methods to handle EPUB resizing
  toggleSidebar(event: Event): void {
    event.preventDefault();
    this.sidebarOpen = !this.sidebarOpen;
    this.applySidebarWidth(this.sidebarOpen);
    // Wait for transition to complete before resizing
    window.setTimeout(() => {
      if (this.rendition && this.containerTarget) {
        const newWidth = this.containerTarget.clientWidth;
        const newHeight = this.containerTarget.clientHeight;
        this.rendition.resize(newWidth, newHeight);
      }
    }, this.SIDEBAR_TRANSITION_MS);
  }

  closeSidebar(event: Event): void {
    event.preventDefault();
    if (!this.sidebarOpen) return;
    this.sidebarOpen = false;
    this.applySidebarWidth(false);
    // Wait for transition to complete before resizing
    window.setTimeout(() => {
      if (this.rendition && this.containerTarget) {
        const newWidth = this.containerTarget.clientWidth;
        const newHeight = this.containerTarget.clientHeight;
        this.rendition.resize(newWidth, newHeight);
      }
    }, this.SIDEBAR_TRANSITION_MS);
  }

  // Override navigation methods to use EPUB-specific navigation
  prevPage(event: Event): void {
    event.preventDefault();
    if (this.rendition) {
      this.rendition.prev();
    }
  }

  nextPage(event: Event): void {
    event.preventDefault();
    if (this.rendition) {
      this.rendition.next();
    }
  }

  gotoStart(event: Event): void {
    event.preventDefault();
    if (this.book && this.rendition) {
      const firstSection = this.book.spine.get(0);
      if (firstSection) {
        this.rendition.display(firstSection.href);
      }
    }
  }

  gotoEnd(event: Event): void {
    event.preventDefault();
    if (this.book && this.rendition) {
      const lastSection = this.book.spine.get(this.book.spine.length - 1);
      if (lastSection) {
        this.rendition.display(lastSection.href);
      }
    }
  }

  // Override dark mode for EPUB
  toggleDarkMode(event: Event): void {
    event.preventDefault();
    this.documentContentTarget.classList.toggle("bg-gray-900");

    if (this.rendition) {
      // Toggle dark theme for EPUB content
      const isDark =
        this.documentContentTarget.classList.contains("bg-gray-900");
      this.rendition.themes.default({
        body: {
          background: isDark ? "#1f2937" : "#ffffff",
          color: isDark ? "#f3f4f6" : "#000000",
        },
      });
    }
  }

  protected updatePageInfo(): void {
    const page = this.currentPage;
    const total = this.totalPages;
    const progress = total > 0 ? (page / total) * 100 : 0;

    this.pageIndicatorTarget.textContent = `Location ${page}/${total} (${progress.toFixed(0)}%)`;
    this.toolbarPageInfoTarget.textContent = `Location ${page} of ${total} (${progress.toFixed(0)}%)`;

    this.progressBarTarget.style.width = `${progress.toFixed(2)}%`;

    this.pageJumpInputTarget.value = String(page);

    this.prevButtonTarget.disabled = page <= 1;
    this.nextButtonTarget.disabled = page >= total;
  }

  disconnect(): void {
    super.disconnect();
    if (this.rendition) {
      this.rendition.destroy();
    }
    if (this.book) {
      this.book.destroy();
    }
  }
}
