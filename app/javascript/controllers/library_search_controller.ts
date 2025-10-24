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

  protected buildSearchParams(): URLSearchParams {
    const params = new URLSearchParams(); // Don't preserve existing params
    params.set('search', this.inputTarget.value);
    return params;
  }
}
