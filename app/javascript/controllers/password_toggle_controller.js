import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "icon"];

  toggle() {
    const input = this.inputTarget;
    const icon = this.iconTarget;

    if (input.type === "password") {
      input.type = "text";
      icon.classList.remove("fa-eye");
      icon.classList.add("fa-eye-slash");
    } else {
      input.type = "password";
      icon.classList.remove("fa-eye-slash");
      icon.classList.add("fa-eye");
    }
  }
}
