import SearchController from "./search_controller";

// Extends base SearchController with staff_list frame
export default class extends SearchController {
  static targets = ["input", "select"];

  declare readonly inputTarget: HTMLInputElement;
  declare readonly selectTarget: HTMLSelectElement;

  protected buildSearchParams(): URLSearchParams {
    const params = new URLSearchParams(window.location.search);
    params.set('search', this.inputTarget.value);
    params.set('status', this.selectTarget.value);
    return params;
  }
}
