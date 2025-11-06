import * as pdfjsLib from "pdfjs-dist";
import ReaderController from "./reader_controller";

type PDFDocument = pdfjsLib.PDFDocumentProxy;
type PDFPage = pdfjsLib.PDFPageProxy;

const WORKER_VERSION = "5.4.296" as const;

export default class PdfReaderController extends ReaderController {
  private pdfDoc: PDFDocument | null = null;

  protected async initReader(): Promise<void> {
    pdfjsLib.GlobalWorkerOptions.workerSrc = `https://unpkg.com/pdfjs-dist@${WORKER_VERSION}/build/pdf.worker.min.mjs`;

    try {
      const task = pdfjsLib.getDocument(this.urlValue);
      this.pdfDoc = await task.promise;
      this.totalPages = this.pdfDoc.numPages;
      this.pageJumpInputTarget.max = String(this.totalPages);

      await this.renderPage(this.currentPage);
      void this.loadOutline();
    } catch (error) {
      this.showError("Error loading PDF", error);
    }
  }

  protected async renderPage(pageNum: number): Promise<void> {
    if (!this.pdfDoc) return;
    this.pageRendering = true;

    try {
      const page: PDFPage = await this.pdfDoc.getPage(pageNum);

      const viewportAt1 = page.getViewport({ scale: 1 });
      const { scale, cssWidth } = this.computeScaleFromNaturalWidth(
        viewportAt1.width
      );

      const dpr = window.devicePixelRatio || 1;
      const viewport = page.getViewport({ scale });

      if (!this.ctx) return;

      this.canvasTarget.width = Math.floor(viewport.width * dpr);
      this.canvasTarget.height = Math.floor(viewport.height * dpr);
      this.canvasTarget.style.width = `${cssWidth}px`;
      this.canvasTarget.style.height = `${viewport.height}px`;

      const renderContext = {
        canvasContext: this.ctx,
        viewport,
      };

      if (dpr !== 1) {
        (renderContext as any).transform = [dpr, 0, 0, dpr, 0, 0];
      }

      await page.render(renderContext as any).promise;

      this.loadingTarget.classList.add("hidden");
      this.documentContentTarget.scrollTop = 0;

      if (this.pageNumPending !== null) {
        const next = this.pageNumPending;
        this.pageNumPending = null;
        await this.renderPage(next);
        return;
      }

      this.updatePageInfo();
    } catch (error) {
      this.showError("Error rendering page", error);
    } finally {
      this.pageRendering = false;
    }
  }

  protected async loadOutline(): Promise<void> {
    try {
      if (!this.pdfDoc) return;
      const outline = await this.pdfDoc.getOutline();
      if (outline && outline.length) {
        this.outlineContainerTarget.innerHTML = "";
        this.renderOutlineItems(
          outline as any[],
          this.outlineContainerTarget,
          0
        );
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
            item.title || "Untitled"
          )}</span>
        </div>
      `;

      row.addEventListener("click", async () => {
        try {
          if (!this.pdfDoc || !item.dest) return;
          const dest = await this.pdfDoc.getDestination(item.dest);
          if (!dest) return;
          const pageRef = Array.isArray(dest) ? dest[0] : dest;
          const index = await this.pdfDoc!.getPageIndex(pageRef as any);
          this.currentPage = index + 1;
          this.queueRenderPage(this.currentPage);
        } catch (err) {
          this.showError("Unable to navigate to outline destination", err);
        }
      });

      container.appendChild(row);

      if (item.items && item.items.length) {
        this.renderOutlineItems(item.items, container, level + 1);
      }
    }
  }
}
