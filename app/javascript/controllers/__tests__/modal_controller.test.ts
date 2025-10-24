import { Application } from '@hotwired/stimulus';
import ModalController from '../modal_controller';

describe('ModalController', () => {
  let application: Application;
  let container: HTMLDivElement;
  let modal: HTMLDialogElement;

  const createModal = (): void => {
    const html = `
      <dialog data-controller="modal">
        <div class="modal-content">
          <h2>Modal Title</h2>
          <p>Modal content</p>
        </div>
      </dialog>
    `;
    container.innerHTML = html;
    modal = container.querySelector('dialog')!;
  };

  beforeEach(() => {
    application = Application.start();
    application.register('modal', ModalController);
    container = document.createElement('div');
    document.body.appendChild(container);
    createModal();
  });

  afterEach(() => {
    application.stop();
    document.body.removeChild(container);
  });

  describe('connect', () => {
    it('shows the modal when connected', () => {
      // Controller connects automatically when element is added to DOM
      expect(modal.open).toBe(true);
    });
  });

  describe('close on backdrop click', () => {
    it('closes when clicking the backdrop', () => {
      const controller = application.getControllerForElementAndIdentifier(modal, 'modal') as ModalController;
      const closeSpy = jest.spyOn(controller, 'close');

      // Simulate clicking on the dialog element itself (backdrop)
      const clickEvent = new MouseEvent('click', { bubbles: true });
      Object.defineProperty(clickEvent, 'target', { value: modal, enumerable: true });
      modal.dispatchEvent(clickEvent);

      expect(closeSpy).toHaveBeenCalled();

      closeSpy.mockRestore();
    });

    it('does not close when clicking content inside modal', () => {
      const controller = application.getControllerForElementAndIdentifier(modal, 'modal') as ModalController;
      const closeSpy = jest.spyOn(controller, 'close');

      const content = modal.querySelector('.modal-content') as HTMLElement;

      // Simulate clicking on content inside the modal
      const clickEvent = new MouseEvent('click', { bubbles: true });
      Object.defineProperty(clickEvent, 'target', { value: content, enumerable: true });
      modal.dispatchEvent(clickEvent);

      expect(closeSpy).not.toHaveBeenCalled();

      closeSpy.mockRestore();
    });
  });

  describe('submitEnd', () => {
    it('closes modal on successful form submission', () => {
      const controller = application.getControllerForElementAndIdentifier(modal, 'modal') as ModalController;
      const closeSpy = jest.spyOn(controller, 'close');

      const event = new CustomEvent('turbo:submit-end', {
        detail: { success: true }
      });

      controller.submitEnd(event);

      expect(closeSpy).toHaveBeenCalled();

      closeSpy.mockRestore();
    });

    it('does not close modal on failed form submission', () => {
      const controller = application.getControllerForElementAndIdentifier(modal, 'modal') as ModalController;
      const closeSpy = jest.spyOn(controller, 'close');

      const event = new CustomEvent('turbo:submit-end', {
        detail: { success: false }
      });

      controller.submitEnd(event);

      expect(closeSpy).not.toHaveBeenCalled();

      closeSpy.mockRestore();
    });
  });

  describe('close', () => {
    it('closes and removes the modal', () => {
      const controller = application.getControllerForElementAndIdentifier(modal, 'modal') as ModalController;

      expect(modal.open).toBe(true);

      controller.close();

      expect(modal.open).toBe(false);
      expect(container.querySelector('dialog')).toBeNull();
    });
  });
});
