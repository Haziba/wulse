import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "preview", "removeCheckbox", "removeButton"];
  static values = { initials: String };

  preview() {
    const file = this.inputTarget.files[0];

    if (file) {
      const reader = new FileReader();

      reader.onload = (e) => {
        // Update the preview image
        this.previewTarget.innerHTML = `
          <img src="${e.target.result}" alt="Profile Picture Preview" class="w-24 h-24 rounded-full object-cover border-4 border-gray-200">
        `;

        // Show remove button if hidden
        if (this.hasRemoveButtonTarget) {
          this.removeButtonTarget.classList.remove("hidden");
        }
      };

      reader.readAsDataURL(file);
    }
  }

  remove(event) {
    event.preventDefault();

    // Clear the file input
    this.inputTarget.value = "";

    // Mark for removal
    if (this.hasRemoveCheckboxTarget) {
      this.removeCheckboxTarget.value = "1";
    }

    // Show default avatar with initials
    this.previewTarget.innerHTML = `
      <div class="w-24 h-24 bg-brand-500 rounded-full flex items-center justify-center">
        <span class="text-white text-2xl font-medium">${this.initialsValue}</span>
      </div>
    `;

    // Hide remove button
    if (this.hasRemoveButtonTarget) {
      this.removeButtonTarget.classList.add("hidden");
    }
  }
}
