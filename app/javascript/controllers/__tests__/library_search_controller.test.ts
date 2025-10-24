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
        '/library?search=',
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
});
