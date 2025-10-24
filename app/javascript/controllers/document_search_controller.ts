import SearchController from "./search_controller";

// Extends base SearchController for document searching
export default class extends SearchController {
  static targets = ["input"];

  declare readonly inputTarget: HTMLInputElement;

  protected buildSearchParams(): URLSearchParams {
    const params = new URLSearchParams(window.location.search);
    params.set('search', this.inputTarget.value);
    return params;
  }
}
