import SearchController from "./search_controller";

export default class extends SearchController {
  static targets = ["input"];
  static values = {
    ...SearchController.values,
    preserveParams: { type: Boolean, default: false },
  };

  declare readonly inputTarget: HTMLInputElement;
  declare readonly hasInputTarget: boolean;

  protected buildSearchParams(): URLSearchParams {
    const params = new URLSearchParams();

    if (this.hasInputTarget && this.inputTarget.value) {
      params.set("q", this.inputTarget.value);
    }

    const checkboxes = document.querySelectorAll<HTMLInputElement>(
      'input[type="checkbox"][data-param]'
    );
    const filterGroups = new Map<
      string,
      { checked: string[]; total: number }
    >();

    checkboxes.forEach((checkbox) => {
      const paramName = checkbox.dataset.param;
      if (paramName) {
        if (!filterGroups.has(paramName)) {
          filterGroups.set(paramName, { checked: [], total: 0 });
        }
        const group = filterGroups.get(paramName)!;
        group.total++;
        if (checkbox.checked) {
          group.checked.push(checkbox.value);
        }
      }
    });

    filterGroups.forEach((group, key) => {
      if (group.checked.length < group.total) {
        group.checked.forEach((value) => {
          params.append(`${key}[]`, value);
        });
      }
    });

    return params;
  }
}
