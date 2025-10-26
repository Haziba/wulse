import { Application } from '@hotwired/stimulus';
import LibrarySearchController from '../library_search_controller';

describe('LibrarySearchController', () => {
  let application: Application;
  let container: HTMLDivElement;
  let input: HTMLInputElement;

  const createSearchForm = (): void => {
    const html = `
      <div data-controller="library-search" data-library-search-frame-value="library_list">
        <input type="text"
               data-library-search-target="input"
               data-action="input->library-search#searchDebounced">
      </div>
    `;
    container.innerHTML = html;
    input = container.querySelector('[data-library-search-target="input"]')!;
  };

  beforeEach(() => {
    jest.useFakeTimers();
    application = Application.start();
    application.register('library-search', LibrarySearchController);
    container = document.createElement('div');
    document.body.appendChild(container);

    // Mock Turbo.visit
    global.Turbo = {
      visit: jest.fn()
    };

    // Mock window.location
    delete (window as any).location;
    window.location = {
      pathname: '/library',
      search: ''
    } as any;

    createSearchForm();
  });

  afterEach(() => {
    application.stop();
    document.body.removeChild(container);
    jest.useRealTimers();
  });

  describe('searchDebounced', () => {
    it('debounces search input', () => {
      input.value = 'physics';
      input.dispatchEvent(new Event('input', { bubbles: true }));

      expect(Turbo.visit).not.toHaveBeenCalled();

      jest.advanceTimersByTime(299);
      expect(Turbo.visit).not.toHaveBeenCalled();

      jest.advanceTimersByTime(1);
      expect(Turbo.visit).toHaveBeenCalled();
    });

    it('cancels previous timeout when typing quickly', () => {
      input.value = 'p';
      input.dispatchEvent(new Event('input', { bubbles: true }));

      jest.advanceTimersByTime(100);

      input.value = 'ph';
      input.dispatchEvent(new Event('input', { bubbles: true }));

      jest.advanceTimersByTime(100);

      input.value = 'phy';
      input.dispatchEvent(new Event('input', { bubbles: true }));

      // Only one call after debounce completes
      jest.advanceTimersByTime(300);
      expect(Turbo.visit).toHaveBeenCalledTimes(1);
    });
  });

  describe('search', () => {
    it('visits correct URL with search param', () => {
      input.value = 'mathematics';

      // Trigger search directly
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector('[data-controller="library-search"]')!,
        'library-search'
      ) as LibrarySearchController;
      controller.search();

      expect(Turbo.visit).toHaveBeenCalledWith(
        '/library?search=mathematics',
        { frame: 'library_list', action: 'advance' }
      );
    });

    it('handles empty search values', () => {
      input.value = '';

      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector('[data-controller="library-search"]')!,
        'library-search'
      ) as LibrarySearchController;
      controller.search();

      expect(Turbo.visit).toHaveBeenCalledWith(
        '/library?',
        { frame: 'library_list', action: 'advance' }
      );
    });

    it('clears existing URL params when searching', () => {
      // Note: library_search uses new URLSearchParams() instead of reading from window.location.search
      input.value = 'chemistry';

      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector('[data-controller="library-search"]')!,
        'library-search'
      ) as LibrarySearchController;
      controller.search();

      expect(Turbo.visit).toHaveBeenCalledWith(
        '/library?search=chemistry',
        { frame: 'library_list', action: 'advance' }
      );
    });
  });

  describe('disconnect', () => {
    it('clears timeout when controller is disconnected', () => {
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector('[data-controller="library-search"]')!,
        'library-search'
      ) as LibrarySearchController;

      input.value = 'test';
      input.dispatchEvent(new Event('input', { bubbles: true }));

      const clearTimeoutSpy = jest.spyOn(global, 'clearTimeout');

      controller.disconnect();

      expect(clearTimeoutSpy).toHaveBeenCalled();

      clearTimeoutSpy.mockRestore();
    });
  });

  describe('filter checkboxes', () => {
    beforeEach(() => {
      const html = `
        <div>
          <div data-controller="library-search" data-library-search-frame-value="library_list">
            <input type="text"
                   data-library-search-target="input"
                   data-action="input->library-search#searchDebounced">
          </div>

          <!-- Document Type Filters -->
          <div>
            <input type="checkbox" data-param="document_type" name="document_type[]" value="book" checked>
            <input type="checkbox" data-param="document_type" name="document_type[]" value="article" checked>
            <input type="checkbox" data-param="document_type" name="document_type[]" value="journal" checked>
          </div>

          <!-- Department Filters -->
          <div>
            <input type="checkbox" data-param="department" name="department[]" value="computer science" checked>
            <input type="checkbox" data-param="department" name="department[]" value="economics" checked>
          </div>
        </div>
      `;
      container.innerHTML = html;
      input = container.querySelector('[data-library-search-target="input"]')!;
    });

    it('excludes filters when all checkboxes are checked', () => {
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector('[data-controller="library-search"]')!,
        'library-search'
      ) as LibrarySearchController;

      input.value = 'test';
      controller.search();

      // All document_type and department checkboxes are checked, so they should be excluded
      expect(Turbo.visit).toHaveBeenCalledWith(
        '/library?search=test',
        { frame: 'library_list', action: 'advance' }
      );
    });

    it('includes filters when some checkboxes are unchecked', () => {
      const checkboxes = container.querySelectorAll<HTMLInputElement>('[data-param="document_type"]');
      checkboxes[2].checked = false; // Uncheck 'journal'

      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector('[data-controller="library-search"]')!,
        'library-search'
      ) as LibrarySearchController;

      controller.search();

      expect(Turbo.visit).toHaveBeenCalledWith(
        '/library?document_type%5B%5D=book&document_type%5B%5D=article',
        { frame: 'library_list', action: 'advance' }
      );
    });

    it('includes filters when only one checkbox is checked', () => {
      const checkboxes = container.querySelectorAll<HTMLInputElement>('[data-param="document_type"]');
      checkboxes[1].checked = false; // Uncheck 'article'
      checkboxes[2].checked = false; // Uncheck 'journal'

      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector('[data-controller="library-search"]')!,
        'library-search'
      ) as LibrarySearchController;

      controller.search();

      expect(Turbo.visit).toHaveBeenCalledWith(
        '/library?document_type%5B%5D=book',
        { frame: 'library_list', action: 'advance' }
      );
    });

    it('excludes filters when no checkboxes are checked', () => {
      const checkboxes = container.querySelectorAll<HTMLInputElement>('[data-param="document_type"]');
      checkboxes[0].checked = false;
      checkboxes[1].checked = false;
      checkboxes[2].checked = false;

      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector('[data-controller="library-search"]')!,
        'library-search'
      ) as LibrarySearchController;

      controller.search();

      // No checkboxes checked, so no filter params
      expect(Turbo.visit).toHaveBeenCalledWith(
        '/library?',
        { frame: 'library_list', action: 'advance' }
      );
    });

    it('handles multiple filter types independently', () => {
      // Uncheck some document_type filters
      const docTypeCheckboxes = container.querySelectorAll<HTMLInputElement>('[data-param="document_type"]');
      docTypeCheckboxes[2].checked = false; // Uncheck 'journal'

      // Uncheck some department filters
      const deptCheckboxes = container.querySelectorAll<HTMLInputElement>('[data-param="department"]');
      deptCheckboxes[1].checked = false; // Uncheck 'economics'

      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector('[data-controller="library-search"]')!,
        'library-search'
      ) as LibrarySearchController;

      controller.search();

      expect(Turbo.visit).toHaveBeenCalledWith(
        '/library?document_type%5B%5D=book&document_type%5B%5D=article&department%5B%5D=computer+science',
        { frame: 'library_list', action: 'advance' }
      );
    });

    it('combines search term with filter checkboxes', () => {
      const checkboxes = container.querySelectorAll<HTMLInputElement>('[data-param="document_type"]');
      checkboxes[1].checked = false; // Uncheck 'article'
      checkboxes[2].checked = false; // Uncheck 'journal'

      input.value = 'ruby';

      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector('[data-controller="library-search"]')!,
        'library-search'
      ) as LibrarySearchController;

      controller.search();

      expect(Turbo.visit).toHaveBeenCalledWith(
        '/library?search=ruby&document_type%5B%5D=book',
        { frame: 'library_list', action: 'advance' }
      );
    });

    it('collects all checkboxes from the entire document', () => {
      // Verify that checkboxes outside the controller element are still collected
      const checkboxes = container.querySelectorAll<HTMLInputElement>('[data-param="document_type"]');
      checkboxes[1].checked = false; // Uncheck 'article'
      checkboxes[2].checked = false; // Uncheck 'journal'

      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector('[data-controller="library-search"]')!,
        'library-search'
      ) as LibrarySearchController;

      controller.search();

      // Verifies that querySelectorAll in buildSearchParams finds checkboxes
      expect(Turbo.visit).toHaveBeenCalledWith(
        '/library?document_type%5B%5D=book',
        { frame: 'library_list', action: 'advance' }
      );
    });

    it('correctly handles values with special characters', () => {
      // Add a department with special characters
      const specialCharDiv = document.createElement('div');
      specialCharDiv.innerHTML = '<input type="checkbox" data-param="department" name="department[]" value="Arts & Sciences" checked>';
      container.appendChild(specialCharDiv);

      // Uncheck other departments so only special char one is checked
      const deptCheckboxes = container.querySelectorAll<HTMLInputElement>('[data-param="department"]');
      deptCheckboxes[0].checked = false; // Uncheck 'computer science'
      deptCheckboxes[1].checked = false; // Uncheck 'economics'

      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector('[data-controller="library-search"]')!,
        'library-search'
      ) as LibrarySearchController;

      controller.search();

      // URLSearchParams encodes & as %26 and spaces as +
      expect(Turbo.visit).toHaveBeenCalledWith(
        '/library?department%5B%5D=Arts+%26+Sciences',
        { frame: 'library_list', action: 'advance' }
      );
    });
  });
});
