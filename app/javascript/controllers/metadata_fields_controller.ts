import { Controller } from "@hotwired/stimulus";

export default class extends Controller<HTMLElement> {
  static targets = ["container", "row", "template"];

  declare readonly containerTarget: HTMLElement;
  declare readonly rowTargets: HTMLElement[];
  declare readonly templateTarget: HTMLTemplateElement;

  private rowIndex: number = 0;

  connect(): void {
    this.rowIndex = this.rowTargets.length;
  }

  addRow(event: Event): void {
    event.preventDefault();

    const template = this.templateTarget;
    const clone = template.content.cloneNode(true) as DocumentFragment;

    const wrapper = document.createElement("div");
    wrapper.appendChild(clone);
    wrapper.innerHTML = wrapper.innerHTML.replace(/INDEX/g, this.rowIndex.toString());

    this.containerTarget.appendChild(wrapper.firstElementChild!);
    this.rowIndex++;
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
    }
  }
}
