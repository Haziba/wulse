import { Application } from "@hotwired/stimulus";
import MetadataFieldsController from "../metadata_fields_controller";

describe("MetadataFieldsController", () => {
  let application: Application;
  let container: HTMLDivElement;

  beforeEach(() => {
    application = Application.start();
    application.register("metadata-fields", MetadataFieldsController);

    container = document.createElement("div");
    document.body.appendChild(container);
  });

  afterEach(() => {
    application.stop();
    document.body.removeChild(container);
  });

  describe("connect", () => {
    beforeEach(() => {
      container.innerHTML = `
        <div data-controller="metadata-fields">
          <div data-metadata-fields-target="container">
            <div data-metadata-fields-target="row">
              <input name="document[metadata_attributes][0][key]" />
              <input name="document[metadata_attributes][0][value]" />
            </div>
            <div data-metadata-fields-target="row">
              <input name="document[metadata_attributes][1][key]" />
              <input name="document[metadata_attributes][1][value]" />
            </div>
            <div data-metadata-fields-target="row">
              <input name="document[metadata_attributes][2][key]" />
              <input name="document[metadata_attributes][2][value]" />
            </div>
          </div>
          <template data-metadata-fields-target="template">
            <div class="grid grid-cols-2 gap-4" data-metadata-fields-target="row">
              <div>
                <input type="text" name="document[metadata_attributes][INDEX][key]" placeholder="Enter key" class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent">
              </div>
              <div class="flex gap-2">
                <input type="text" name="document[metadata_attributes][INDEX][value]" placeholder="Enter value" class="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent">
                <button type="button" class="text-red-600 hover:text-red-800 px-2" data-action="click->metadata-fields#removeRow">
                  <i class="fas fa-trash"></i>
                </button>
              </div>
              <input type="hidden" name="document[metadata_attributes][INDEX][_destroy]" value="0">
            </div>
          </template>
          <button data-action="click->metadata-fields#addRow">Add Row</button>
        </div>
      `;
    });

    it("sets rowIndex based on existing rows", () => {
      const button = container.querySelector("button") as HTMLButtonElement;
      button.click();

      const fieldContainer = container.querySelector(
        '[data-metadata-fields-target="container"]'
      ) as HTMLElement;
      const rows = fieldContainer.querySelectorAll(
        '[data-metadata-fields-target="row"]'
      );

      expect(rows.length).toBe(4);
      const lastRow = rows[rows.length - 1] as HTMLElement;
      const keyInput = lastRow.querySelector(
        'input[name*="[key]"]'
      ) as HTMLInputElement;
      expect(keyInput.name).toBe("document[metadata_attributes][3][key]");
    });
  });

  describe("addRow", () => {
    beforeEach(() => {
      container.innerHTML = `
        <div data-controller="metadata-fields">
          <div data-metadata-fields-target="container"></div>
          <template data-metadata-fields-target="template">
            <div class="grid grid-cols-2 gap-4" data-metadata-fields-target="row">
              <div>
                <input type="text" name="document[metadata_attributes][INDEX][key]" placeholder="Enter key" class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent">
              </div>
              <div class="flex gap-2">
                <input type="text" name="document[metadata_attributes][INDEX][value]" placeholder="Enter value" class="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent">
                <button type="button" class="text-red-600 hover:text-red-800 px-2" data-action="click->metadata-fields#removeRow">
                  <i class="fas fa-trash"></i>
                </button>
              </div>
              <input type="hidden" name="document[metadata_attributes][INDEX][_destroy]" value="0">
            </div>
          </template>
          <button data-action="click->metadata-fields#addRow">Add Row</button>
        </div>
      `;
    });

    it("adds a new metadata row to the container", () => {
      const button = container.querySelector("button") as HTMLButtonElement;
      const fieldContainer = container.querySelector(
        '[data-metadata-fields-target="container"]'
      ) as HTMLElement;

      expect(fieldContainer.children.length).toBe(0);

      button.click();

      expect(fieldContainer.children.length).toBe(1);
    });

    it("creates a row with correct structure", () => {
      const button = container.querySelector("button") as HTMLButtonElement;
      button.click();

      const fieldContainer = container.querySelector(
        '[data-metadata-fields-target="container"]'
      ) as HTMLElement;
      const row = fieldContainer.firstElementChild as HTMLElement;

      expect(row.className).toBe("grid grid-cols-2 gap-4");
      expect(row.dataset.metadataFieldsTarget).toBe("row");
    });

    it("creates inputs with correct names", () => {
      const button = container.querySelector("button") as HTMLButtonElement;
      button.click();

      const fieldContainer = container.querySelector(
        '[data-metadata-fields-target="container"]'
      ) as HTMLElement;
      const row = fieldContainer.firstElementChild as HTMLElement;

      const keyInput = row.querySelector(
        'input[name*="[key]"]'
      ) as HTMLInputElement;
      const valueInput = row.querySelector(
        'input[name*="[value]"]'
      ) as HTMLInputElement;

      expect(keyInput.name).toBe("document[metadata_attributes][0][key]");
      expect(valueInput.name).toBe("document[metadata_attributes][0][value]");
      expect(keyInput.placeholder).toBe("Enter key");
      expect(valueInput.placeholder).toBe("Enter value");
    });

    it("includes a delete button", () => {
      const button = container.querySelector("button") as HTMLButtonElement;
      button.click();

      const fieldContainer = container.querySelector(
        '[data-metadata-fields-target="container"]'
      ) as HTMLElement;
      const row = fieldContainer.firstElementChild as HTMLElement;

      const deleteButton = row.querySelector(
        'button[data-action="click->metadata-fields#removeRow"]'
      ) as HTMLButtonElement;

      expect(deleteButton).toBeTruthy();
      expect(deleteButton.querySelector("i.fa-trash")).toBeTruthy();
    });

    it("increments rowIndex for each new row", () => {
      const button = container.querySelector("button") as HTMLButtonElement;

      button.click();
      button.click();
      button.click();

      const fieldContainer = container.querySelector(
        '[data-metadata-fields-target="container"]'
      ) as HTMLElement;
      const rows = fieldContainer.querySelectorAll(
        '[data-metadata-fields-target="row"]'
      );

      expect(rows.length).toBe(3);

      const keyInputs = Array.from(
        fieldContainer.querySelectorAll('input[name*="[key]"]')
      ) as HTMLInputElement[];

      expect(keyInputs[0].name).toBe("document[metadata_attributes][0][key]");
      expect(keyInputs[1].name).toBe("document[metadata_attributes][1][key]");
      expect(keyInputs[2].name).toBe("document[metadata_attributes][2][key]");
    });

    it("prevents default event behavior", () => {
      const button = container.querySelector("button") as HTMLButtonElement;
      const event = new Event("click", { cancelable: true });
      const preventDefault = jest.spyOn(event, "preventDefault");

      button.dispatchEvent(event);

      expect(preventDefault).toHaveBeenCalled();
    });
  });

  describe("removeRow", () => {
    describe("for all rows", () => {
      beforeEach(() => {
        container.innerHTML = `
          <div data-controller="metadata-fields">
            <div data-metadata-fields-target="container">
              <div data-metadata-fields-target="row">
                <input name="document[metadata_attributes][0][key]" />
                <input name="document[metadata_attributes][0][value]" />
                <input type="hidden" name="document[metadata_attributes][0][_destroy]" value="0" />
                <button type="button" data-action="click->metadata-fields#removeRow">
                  <i class="fas fa-trash"></i>
                </button>
              </div>
            </div>
          </div>
        `;
      });

      it("sets _destroy field to 1", () => {
        const destroyField = container.querySelector(
          'input[name*="_destroy"]'
        ) as HTMLInputElement;
        const button = container.querySelector(
          'button[data-action="click->metadata-fields#removeRow"]'
        ) as HTMLButtonElement;

        expect(destroyField.value).toBe("0");

        button.click();

        expect(destroyField.value).toBe("1");
      });

      it("hides the row", () => {
        const row = container.querySelector(
          '[data-metadata-fields-target="row"]'
        ) as HTMLElement;
        const button = container.querySelector(
          'button[data-action="click->metadata-fields#removeRow"]'
        ) as HTMLButtonElement;

        expect(row.style.display).toBe("");

        button.click();

        expect(row.style.display).toBe("none");
      });

      it("does not remove the row from the DOM", () => {
        const fieldContainer = container.querySelector(
          '[data-metadata-fields-target="container"]'
        ) as HTMLElement;
        const button = container.querySelector(
          'button[data-action="click->metadata-fields#removeRow"]'
        ) as HTMLButtonElement;

        expect(fieldContainer.children.length).toBe(1);

        button.click();

        expect(fieldContainer.children.length).toBe(1);
      });
    });

    describe("preventDefault behavior", () => {
      beforeEach(() => {
        container.innerHTML = `
          <div data-controller="metadata-fields">
            <div data-metadata-fields-target="container">
              <div data-metadata-fields-target="row">
                <input name="document[metadata_attributes][0][key]" />
                <input name="document[metadata_attributes][0][value]" />
                <button type="button" data-action="click->metadata-fields#removeRow">Delete</button>
              </div>
            </div>
          </div>
        `;
      });

      it("prevents default event behavior", () => {
        const button = container.querySelector("button") as HTMLButtonElement;
        const event = new Event("click", { cancelable: true });
        const preventDefault = jest.spyOn(event, "preventDefault");

        button.dispatchEvent(event);

        expect(preventDefault).toHaveBeenCalled();
      });
    });
  });

  describe("integration", () => {
    beforeEach(() => {
      container.innerHTML = `
        <div data-controller="metadata-fields">
          <div data-metadata-fields-target="container"></div>
          <template data-metadata-fields-target="template">
            <div class="grid grid-cols-2 gap-4" data-metadata-fields-target="row">
              <div>
                <input type="text" name="document[metadata_attributes][INDEX][key]" placeholder="Enter key" class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent">
              </div>
              <div class="flex gap-2">
                <input type="text" name="document[metadata_attributes][INDEX][value]" placeholder="Enter value" class="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent">
                <button type="button" class="text-red-600 hover:text-red-800 px-2" data-action="click->metadata-fields#removeRow">
                  <i class="fas fa-trash"></i>
                </button>
              </div>
              <input type="hidden" name="document[metadata_attributes][INDEX][_destroy]" value="0">
            </div>
          </template>
          <button id="add" data-action="click->metadata-fields#addRow">Add Row</button>
        </div>
      `;
    });

    it("can add multiple rows with delete buttons and _destroy fields", () => {
      const addButton = container.querySelector("#add") as HTMLButtonElement;
      const fieldContainer = container.querySelector(
        '[data-metadata-fields-target="container"]'
      ) as HTMLElement;

      addButton.click();
      addButton.click();
      addButton.click();

      expect(fieldContainer.children.length).toBe(3);

      // Verify all rows have _destroy fields
      const destroyFields = fieldContainer.querySelectorAll(
        'input[name*="_destroy"]'
      );
      expect(destroyFields.length).toBe(3);
      destroyFields.forEach((field) => {
        expect((field as HTMLInputElement).value).toBe("0");
      });

      // Verify all rows have delete buttons
      const deleteButtons = fieldContainer.querySelectorAll(
        'button[data-action*="removeRow"]'
      );
      expect(deleteButtons.length).toBe(3);

      // Verify rows have correct incremental indices
      const keyInputs = fieldContainer.querySelectorAll('input[name*="[key]"]');
      expect((keyInputs[0] as HTMLInputElement).name).toBe(
        "document[metadata_attributes][0][key]"
      );
      expect((keyInputs[1] as HTMLInputElement).name).toBe(
        "document[metadata_attributes][1][key]"
      );
      expect((keyInputs[2] as HTMLInputElement).name).toBe(
        "document[metadata_attributes][2][key]"
      );
    });
  });
});
