import ReaderController from "./reader_controller";

// epub.js is loaded via script tag and available globally on window
declare global {
  interface Window {
    ePub: any;
  }
}

type Book = any; // epub.js types aren't great
type Rendition = any;

export default class EpubReaderController extends ReaderController {
  private book: Book | null = null;
  private rendition: Rendition | null = null;

  connect(): void {
    console.log("EPUB Reader Controller connected!");
    console.log("URL value:", this.urlValue);
    console.log("Document title:", this.documentTitleValue);
    super.connect();
  }

  protected async initReader(): Promise<void> {
    try {
      // Check if ePub is available
      if (typeof window.ePub === "undefined") {
        throw new Error("ePub library is not loaded. Make sure epub.min.js is included in the page.");
      }

      console.log("Loading EPUB from:", this.urlValue);
      this.book = window.ePub(this.urlValue);

      console.log("Waiting for book ready...");
      // Wait for book to be ready before creating rendition
      await this.book.ready;

      // Hide loading, show container BEFORE creating rendition
      // epub.js needs the container to be visible to calculate dimensions
      this.loadingTarget.classList.add("hidden");
      this.containerTarget.classList.remove("hidden");

      console.log("Creating rendition...");
      // Create rendition in the container
      this.rendition = this.book.renderTo(this.containerTarget, {
        width: "100%",
        height: "100%",
        spread: "none",
      });

      console.log("Displaying first location...");
      // Display the first location
      await this.rendition.display();

      console.log("Display completed!");

      console.log("Loading navigation...");
      // Load navigation
      await this.book.loaded.navigation;
      this.totalPages = this.book.spine.length;
      this.pageJumpInputTarget.max = String(this.totalPages);

      console.log("Setting up location handler...");
      // Set up location changed handler
      this.rendition.on("relocated", (location: any) => {
        const spinePos = this.book.spine.get(location.start.cfi);
        if (spinePos) {
          this.currentPage = spinePos.index + 1;
          this.updatePageInfo();
        }
      });

      // Initial page info
      this.currentPage = 1;
      this.updatePageInfo();

      console.log("EPUB loaded successfully");

      // Load table of contents
      void this.loadOutline();
    } catch (error) {
      console.error("Error loading EPUB:", error);
      this.showError("Error loading EPUB", error);
    }
  }

  protected async renderPage(pageNum: number): Promise<void> {
    if (!this.book || !this.rendition) return;

    try {
      // EPUB pages are called "spine items"
      const section = this.book.spine.get(pageNum - 1);
      if (section) {
        await this.rendition.display(section.href);
        this.currentPage = pageNum;
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
      const isDark = this.documentContentTarget.classList.contains("bg-gray-900");
      this.rendition.themes.default({
        body: {
          background: isDark ? "#1f2937" : "#ffffff",
          color: isDark ? "#f3f4f6" : "#000000",
        },
      });
    }
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
