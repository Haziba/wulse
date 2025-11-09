import { Controller } from "@hotwired/stimulus";

export default class FileUploadController extends Controller {
  static targets = ["input", "filename", "filesize", "info"];

  declare readonly inputTarget: HTMLInputElement;
  declare readonly filenameTarget: HTMLElement;
  declare readonly filesizeTarget: HTMLElement;
  declare readonly infoTarget: HTMLElement;

  updatePreview(): void {
    const file = this.inputTarget.files?.[0];

    if (file) {
      this.infoTarget.classList.remove("hidden");
      this.filenameTarget.textContent = file.name;
      this.filesizeTarget.textContent = this.formatFileSize(file.size);
    }
  }

  private formatFileSize(bytes: number): string {
    if (bytes === 0) return "0 Bytes";

    const k = 1024;
    const sizes = ["Bytes", "KB", "MB", "GB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + " " + sizes[i];
  }
}
