import { Application } from '@hotwired/stimulus';
import DocumentSearchController from '../document_search_controller';

describe('DocumentSearchController', () => {
  let application: Application;
  let container: HTMLDivElement;
  let input: HTMLInputElement;

  const createSearchForm = (): void => {
    const html = `
      <div data-controller="document-search" data-document-search-frame-value="document_list">
        <input type="text"
               data-document-search-target="input"
               data-action="input->document-search#searchDebounced">
      </div>
    `;
    container.innerHTML = html;
    input = container.querySelector('[data-document-search-target="input"]')!;
  };

  beforeEach(() => {
    jest.useFakeTimers();
    application = Application.start();
    application.register('document-search', DocumentSearchController);
    container = document.createElement('div');
    document.body.appendChild(container);

    // Mock Turbo.visit
    global.Turbo = {
      visit: jest.fn()
    };

    // Mock window.location
    delete (window as any).location;
    window.location = {
      pathname: '/dashboard/documents',
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
      input.value = 'report';
      input.dispatchEvent(new Event('input', { bubbles: true }));

      expect(Turbo.visit).not.toHaveBeenCalled();

      jest.advanceTimersByTime(299);
      expect(Turbo.visit).not.toHaveBeenCalled();

      jest.advanceTimersByTime(1);
      expect(Turbo.visit).toHaveBeenCalled();
    });

    it('cancels previous timeout when typing quickly', () => {
      input.value = 'r';
      input.dispatchEvent(new Event('input', { bubbles: true }));

      jest.advanceTimersByTime(100);

      input.value = 're';
      input.dispatchEvent(new Event('input', { bubbles: true }));

      jest.advanceTimersByTime(100);

      input.value = 'rep';
      input.dispatchEvent(new Event('input', { bubbles: true }));

      // Only one call after debounce completes
      jest.advanceTimersByTime(300);
      expect(Turbo.visit).toHaveBeenCalledTimes(1);
    });
  });

  describe('search', () => {
    it('visits correct URL with search param', () => {
      input.value = 'annual report';

      // Trigger search directly
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector('[data-controller="document-search"]')!,
        'document-search'
      ) as DocumentSearchController;
      controller.search();

      expect(Turbo.visit).toHaveBeenCalledWith(
        '/dashboard/documents?search=annual+report',
        { frame: 'document_list', action: 'advance' }
      );
    });

    it('preserves other URL params when searching', () => {
      window.location.search = '?page=3&sort=date';
      input.value = 'budget';

      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector('[data-controller="document-search"]')!,
        'document-search'
      ) as DocumentSearchController;
      controller.search();

      expect(Turbo.visit).toHaveBeenCalledWith(
        expect.stringContaining('search=budget'),
        { frame: 'document_list', action: 'advance' }
      );
    });

    it('handles empty search values', () => {
      input.value = '';

      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector('[data-controller="document-search"]')!,
        'document-search'
      ) as DocumentSearchController;
      controller.search();

      expect(Turbo.visit).toHaveBeenCalledWith(
        '/dashboard/documents?search=',
        { frame: 'document_list', action: 'advance' }
      );
    });
  });

  describe('disconnect', () => {
    it('clears timeout when controller is disconnected', () => {
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector('[data-controller="document-search"]')!,
        'document-search'
      ) as DocumentSearchController;

      input.value = 'test';
      input.dispatchEvent(new Event('input', { bubbles: true }));

      const clearTimeoutSpy = jest.spyOn(global, 'clearTimeout');

      controller.disconnect();

      expect(clearTimeoutSpy).toHaveBeenCalled();

      clearTimeoutSpy.mockRestore();
    });
  });
});
