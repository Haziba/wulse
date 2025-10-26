import SearchController from "./search_controller";

// Extends base SearchController for library searching
// Note: Uses preserveParams: false to start with clean params
export default class extends SearchController {
  static targets = ["input"];
  static values = {
    ...SearchController.values,
    preserveParams: { type: Boolean, default: false }
  };

  declare readonly inputTarget: HTMLInputElement;
  declare readonly hasInputTarget: boolean;

  protected buildSearchParams(): URLSearchParams {
    const params = new URLSearchParams();

    // Add search term if input exists
    if (this.hasInputTarget && this.inputTarget.value) {
      params.set('search', this.inputTarget.value);
    }

    // Collect all checkboxes grouped by filter type
    const checkboxes = document.querySelectorAll<HTMLInputElement>('input[type="checkbox"][data-param]');
    const filterGroups = new Map<string, { checked: string[], total: number }>();

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

    // Add filter groups to params only if not all checkboxes are checked
    filterGroups.forEach((group, key) => {
      // Skip only if ALL checkboxes are checked (no filtering needed)
      // If some or none are checked, we need to filter
      if (group.checked.length < group.total) {
        group.checked.forEach(value => {
          params.append(`${key}[]`, value);
        });
      }
    });

    return params;
  }
}
