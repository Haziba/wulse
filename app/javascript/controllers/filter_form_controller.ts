import { Controller } from "@hotwired/stimulus";
import { compressFilters } from "../utils/filter_compression";

export default class extends Controller<HTMLFormElement> {
  static values = {
    filterKeys: { type: Array, default: ["document_type", "department", "language", "publishing_date"] }
  };

  declare readonly filterKeysValue: string[];

  private timeout: ReturnType<typeof setTimeout> | null = null;

  disconnect(): void {
    if (this.timeout) clearTimeout(this.timeout);
  }

  debouncedSubmit(): void {
    if (this.timeout) clearTimeout(this.timeout);

    this.timeout = setTimeout(() => {
      this.submit();
    }, 300);
  }

  submit(): void {
    if (this.timeout) clearTimeout(this.timeout);
    this.compressFiltersAndNavigate();
  }

  private async compressFiltersAndNavigate(): Promise<void> {
    const formData = new FormData(this.element);
    const filters: Record<string, string[]> = {};

    for (const key of this.filterKeysValue) {
      const allCheckboxes = this.element.querySelectorAll<HTMLInputElement>(`input[name="${key}[]"]`);
      const checkedValues = formData.getAll(`${key}[]`) as string[];

      if (checkedValues.length > 0 && checkedValues.length < allCheckboxes.length) {
        filters[key] = checkedValues;
      }
    }

    const url = new URL(this.element.action);

    const q = formData.get("q");
    if (q) {
      url.searchParams.set("q", q as string);
    }

    if (Object.keys(filters).length > 0) {
      const compressed = await compressFilters(filters);
      url.searchParams.set("f", compressed);
    }

    Turbo.visit(url.toString());
  }
}
