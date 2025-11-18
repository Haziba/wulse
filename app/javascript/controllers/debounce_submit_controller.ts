import { Controller } from "@hotwired/stimulus";

export default class DebounceSubmitController extends Controller {
  private timeout: ReturnType<typeof setTimeout> | null = null;

  connect(): void {
    this.timeout = null;
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout);
  }

  debouncedSubmit() {
    if (this.timeout) clearTimeout(this.timeout);

    this.timeout = setTimeout(() => {
      this.submit();
    }, 300);
  }

  submit() {
    if (this.timeout) clearTimeout(this.timeout);
    (this.element as HTMLFormElement).requestSubmit();
  }
}
