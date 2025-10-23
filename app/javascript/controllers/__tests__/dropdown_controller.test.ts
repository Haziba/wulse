import { Application } from '@hotwired/stimulus';
import DropdownController from '../dropdown_controller';

describe('DropdownController', () => {
  let application: Application;
  let container: HTMLDivElement;
  let button: HTMLButtonElement;
  let menu: HTMLElement;

  const createDropdown = (includeOutside = false): void => {
    const html = `
      <div data-controller="dropdown">
        <button type="button" data-action="click->dropdown#toggle">
          Toggle
        </button>
        <div data-dropdown-target="menu" class="hidden">
          <a href="#" id="menu-item">Menu item</a>
        </div>
      </div>
      ${includeOutside ? '<div id="outside">Outside element</div>' : ''}
    `;
    container.innerHTML = html;
    button = container.querySelector('button')!;
    menu = container.querySelector('[data-dropdown-target="menu"]')!;
  };

  beforeEach(() => {
    // Set up a Stimulus application for testing
    application = Application.start();
    application.register('dropdown', DropdownController);

    // Create a container for the DOM
    container = document.createElement('div');
    document.body.appendChild(container);

    // Set up default dropdown
    createDropdown();
  });

  afterEach(() => {
    // Clean up
    application.stop();
    document.body.removeChild(container);
  });

  describe('toggle', () => {
    it('shows the menu when clicking the button', () => {
      expect(menu).toHaveClass('hidden');

      button.click();

      expect(menu).not.toHaveClass('hidden');
    });

    it('hides the menu when clicking the button again', () => {
      // Open menu
      button.click();
      expect(menu).not.toHaveClass('hidden');

      // Close menu
      button.click();
      expect(menu).toHaveClass('hidden');
    });

    it('prevents event propagation when toggling', () => {
      const stopPropagationSpy = jest.fn();

      button.addEventListener('click', (event) => {
        const originalStopPropagation = event.stopPropagation;
        event.stopPropagation = () => {
          stopPropagationSpy();
          originalStopPropagation.call(event);
        };
      }, true);

      button.click();

      expect(stopPropagationSpy).toHaveBeenCalled();
    });
  });

  describe('click outside behavior', () => {
    beforeEach(() => {
      createDropdown(true);
    });

    it('closes the menu when clicking outside', () => {
      const outsideElement = container.querySelector('#outside') as HTMLElement;

      // Open menu
      button.click();
      expect(menu).not.toHaveClass('hidden');

      // Click outside
      outsideElement.click();

      expect(menu).toHaveClass('hidden');
    });

    it('does not close the menu when clicking inside', () => {
      const menuItem = container.querySelector('#menu-item') as HTMLElement;

      // Open menu
      button.click();
      expect(menu).not.toHaveClass('hidden');

      // Click inside menu
      menuItem.click();

      expect(menu).not.toHaveClass('hidden');
    });

    it('removes event listener when menu is closed', () => {
      const outsideElement = container.querySelector('#outside') as HTMLElement;

      // Open and close menu with button
      button.click();
      expect(menu).not.toHaveClass('hidden');
      button.click();
      expect(menu).toHaveClass('hidden');

      // Click outside shouldn't do anything now
      outsideElement.click();
      expect(menu).toHaveClass('hidden');
    });
  });

  describe('disconnect', () => {
    beforeEach(() => {
      createDropdown(true);
    });

    it('removes click listener when controller is disconnected', () => {
      const dropdownElement = container.querySelector('[data-controller="dropdown"]') as HTMLElement;
      const controller = application.getControllerForElementAndIdentifier(dropdownElement, 'dropdown') as DropdownController;

      const removeEventListenerSpy = jest.spyOn(document, 'removeEventListener');

      // Open menu to add the listener
      button.click();
      expect(menu).not.toHaveClass('hidden');

      // Manually call disconnect to test cleanup behavior
      controller.disconnect();

      // Verify removeEventListener was called
      expect(removeEventListenerSpy).toHaveBeenCalledWith('click', expect.any(Function));

      removeEventListenerSpy.mockRestore();
    });
  });
});
