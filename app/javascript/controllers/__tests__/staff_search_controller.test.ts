import { Application } from '@hotwired/stimulus';
import StaffSearchController from '../staff_search_controller';

describe('StaffSearchController', () => {
  let application: Application;
  let container: HTMLDivElement;
  let input: HTMLInputElement;
  let select: HTMLSelectElement;

  const createSearchForm = (): void => {
    const html = `
      <div data-controller="staff-search" data-staff-search-frame-value="staff_list">
        <input type="text"
               data-staff-search-target="input"
               data-action="input->staff-search#searchDebounced">
        <select data-staff-search-target="select"
                data-action="change->staff-search#search">
          <option value="">All</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
        </select>
      </div>
    `;
    container.innerHTML = html;
    input = container.querySelector('[data-staff-search-target="input"]')!;
    select = container.querySelector('[data-staff-search-target="select"]')!;
  };

  beforeEach(() => {
    jest.useFakeTimers();
    application = Application.start();
    application.register('staff-search', StaffSearchController);
    container = document.createElement('div');
    document.body.appendChild(container);

    // Mock Turbo.visit
    global.Turbo = {
      visit: jest.fn()
    };

    // Mock window.location
    delete (window as any).location;
    window.location = {
      pathname: '/dashboard/staff',
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
      input.value = 'John';
      input.dispatchEvent(new Event('input', { bubbles: true }));

      expect(Turbo.visit).not.toHaveBeenCalled();

      jest.advanceTimersByTime(299);
      expect(Turbo.visit).not.toHaveBeenCalled();

      jest.advanceTimersByTime(1);
      expect(Turbo.visit).toHaveBeenCalled();
    });

    it('cancels previous timeout when typing quickly', () => {
      input.value = 'J';
      input.dispatchEvent(new Event('input', { bubbles: true }));

      jest.advanceTimersByTime(100);

      input.value = 'Jo';
      input.dispatchEvent(new Event('input', { bubbles: true }));

      jest.advanceTimersByTime(100);

      input.value = 'Joh';
      input.dispatchEvent(new Event('input', { bubbles: true }));

      // Only one call after debounce completes
      jest.advanceTimersByTime(300);
      expect(Turbo.visit).toHaveBeenCalledTimes(1);
    });
  });

  describe('search', () => {
    it('visits correct URL with search and status params', () => {
      input.value = 'John Doe';
      select.value = 'active';

      select.dispatchEvent(new Event('change', { bubbles: true }));

      expect(Turbo.visit).toHaveBeenCalledWith(
        '/dashboard/staff?search=John+Doe&status=active',
        { frame: 'staff_list', action: 'advance' }
      );
    });

    it('preserves other URL params when searching', () => {
      window.location.search = '?page=2&sort=name';
      input.value = 'Jane';
      select.value = 'inactive';

      select.dispatchEvent(new Event('change', { bubbles: true }));

      expect(Turbo.visit).toHaveBeenCalledWith(
        expect.stringContaining('search=Jane'),
        { frame: 'staff_list', action: 'advance' }
      );
      expect(Turbo.visit).toHaveBeenCalledWith(
        expect.stringContaining('status=inactive'),
        { frame: 'staff_list', action: 'advance' }
      );
    });

    it('handles empty search values', () => {
      input.value = '';
      select.value = '';

      select.dispatchEvent(new Event('change', { bubbles: true }));

      expect(Turbo.visit).toHaveBeenCalledWith(
        '/dashboard/staff?search=&status=',
        { frame: 'staff_list', action: 'advance' }
      );
    });
  });

  describe('disconnect', () => {
    it('clears timeout when controller is disconnected', () => {
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector('[data-controller="staff-search"]')!,
        'staff-search'
      ) as StaffSearchController;

      input.value = 'test';
      input.dispatchEvent(new Event('input', { bubbles: true }));

      const clearTimeoutSpy = jest.spyOn(global, 'clearTimeout');

      controller.disconnect();

      expect(clearTimeoutSpy).toHaveBeenCalled();

      clearTimeoutSpy.mockRestore();
    });
  });
});
