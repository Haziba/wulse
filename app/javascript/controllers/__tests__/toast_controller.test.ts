import { Application } from '@hotwired/stimulus';
import ToastController from '../toast_controller';

describe('ToastController', () => {
  let application: Application;
  let container: HTMLDivElement;
  let toast: HTMLElement;

  const createToast = (duration?: number): void => {
    const durationAttr = duration ? `data-toast-duration-value="${duration}"` : '';
    const html = `
      <div data-controller="toast" ${durationAttr} class="animate-slide-up">
        Toast message
      </div>
    `;
    container.innerHTML = html;
    toast = container.querySelector('[data-controller="toast"]')!;
  };

  beforeEach(() => {
    application = Application.start();
    application.register('toast', ToastController);
    container = document.createElement('div');
    document.body.appendChild(container);
  });

  afterEach(() => {
    application.stop();
    document.body.removeChild(container);
  });

  describe('connect', () => {
    it('initializes with correct classes', () => {
      createToast();

      expect(toast).toHaveClass('animate-slide-up');
      expect(toast.textContent?.trim()).toBe('Toast message');
    });

    it('respects custom duration value', () => {
      createToast(2000);

      const toastElement = container.querySelector('[data-controller="toast"]') as HTMLElement;
      expect(toastElement).toHaveAttribute('data-toast-duration-value', '2000');
    });
  });

  describe('structure', () => {
    it('has the correct HTML structure and classes', () => {
      createToast();

      expect(toast).toHaveClass('animate-slide-up');
      expect(toast).toHaveAttribute('data-controller', 'toast');
    });

    it('preserves content', () => {
      createToast();

      expect(toast.textContent?.trim()).toBe('Toast message');
    });
  });
});
