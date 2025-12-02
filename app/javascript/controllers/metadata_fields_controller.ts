import { Controller } from "@hotwired/stimulus";

export default class extends Controller<HTMLElement> {
  static targets = ["container", "row", "template"];

  declare readonly containerTarget: HTMLElement;
  declare readonly rowTargets: HTMLElement[];
  declare readonly templateTarget: HTMLTemplateElement;

  private rowIndex: number = 0;
  private allKeySuggestions: string[] = [];

  connect(): void {
    this.rowIndex = this.rowTargets.length;
    this.storeOriginalKeySuggestions();
    this.updateKeySuggestions();
    this.loadExistingSuggestions();
  }

  private storeOriginalKeySuggestions(): void {
    const datalist = document.getElementById('metadata-key-suggestions') as HTMLDataListElement;
    if (datalist) {
      this.allKeySuggestions = Array.from(datalist.options).map(opt => opt.value);
    }
  }

  private getUsedKeys(): string[] {
    const usedKeys: string[] = [];
    for (const row of this.rowTargets) {
      if (row.style.display === 'none') continue;
      const keyInput = row.querySelector('input[name*="[key]"]:not([type="hidden"])') as HTMLInputElement;
      if (keyInput && keyInput.value.trim()) {
        usedKeys.push(keyInput.value.trim().toLowerCase());
      }
    }
    return usedKeys;
  }

  private updateKeySuggestions(): void {
    const datalist = document.getElementById('metadata-key-suggestions') as HTMLDataListElement;
    if (!datalist) return;

    const usedKeys = this.getUsedKeys();
    const availableKeys = this.allKeySuggestions.filter(
      key => !usedKeys.includes(key.toLowerCase())
    );

    datalist.innerHTML = '';
    availableKeys.forEach(key => {
      const option = document.createElement('option');
      option.value = key;
      datalist.appendChild(option);
    });
  }

  private async loadExistingSuggestions(): Promise<void> {
    for (const row of this.rowTargets) {
      const keyInput = row.querySelector('input[name*="[key]"]:not([type="hidden"])') as HTMLInputElement;
      if (keyInput && keyInput.value.trim()) {
        await this.fetchAndUpdateSuggestions(keyInput.value.trim(), row);
      }
    }
  }

  private async fetchAndUpdateSuggestions(key: string, row: HTMLElement): Promise<void> {
    const datalist = row.querySelector('.value-suggestions') as HTMLDataListElement;
    if (!datalist) return;

    const skipAutocompleteKeys = ['title', 'publishing_date'];
    const normalizedKey = key.toLowerCase().replace(/\s+/g, '_');
    if (skipAutocompleteKeys.includes(normalizedKey)) {
      datalist.innerHTML = '';
      return;
    }

    try {
      const response = await fetch(`/dashboard/metadata_suggestions?key=${encodeURIComponent(key)}`);
      if (!response.ok) return;

      const suggestions: string[] = await response.json();

      datalist.innerHTML = '';
      suggestions.forEach(suggestion => {
        const option = document.createElement('option');
        option.value = suggestion;
        datalist.appendChild(option);
      });
    } catch (error) {
      console.error('Failed to fetch metadata suggestions:', error);
    }
  }

  addRow(event: Event): void {
    event.preventDefault();

    const template = this.templateTarget;
    const clone = template.content.cloneNode(true) as DocumentFragment;

    const wrapper = document.createElement("div");
    wrapper.appendChild(clone);
    wrapper.innerHTML = wrapper.innerHTML.replace(/INDEX/g, this.rowIndex.toString());

    const newRow = wrapper.firstElementChild as HTMLElement;
    this.containerTarget.appendChild(newRow);
    this.rowIndex++;

    const keyInput = newRow.querySelector('input[name*="[key]"]') as HTMLInputElement;
    if (keyInput) {
      keyInput.focus();
    }
  }

  removeRow(event: Event): void {
    event.preventDefault();
    const button = event.currentTarget as HTMLElement;
    const row = button.closest(
      '[data-metadata-fields-target="row"]'
    ) as HTMLElement;

    if (row) {
      const destroyField = row.querySelector(
        'input[name*="_destroy"]'
      ) as HTMLInputElement;

      if (destroyField) {
        destroyField.value = "1";
        row.style.display = "none";
      } else {
        row.remove();
      }

      this.updateKeySuggestions();
    }
  }

  async updateValueSuggestions(event: Event): Promise<void> {
    const keyInput = event.currentTarget as HTMLInputElement;
    const key = keyInput.value.trim();
    const row = keyInput.closest('[data-metadata-fields-target="row"]') as HTMLElement;

    this.updateKeySuggestions();

    if (!row || !key) return;

    await this.fetchAndUpdateSuggestions(key, row);
  }
}
