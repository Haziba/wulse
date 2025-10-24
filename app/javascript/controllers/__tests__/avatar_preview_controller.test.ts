import { Application } from '@hotwired/stimulus';
import AvatarPreviewController from '../avatar_preview_controller';

describe('AvatarPreviewController', () => {
  let application: Application;
  let container: HTMLDivElement;
  let input: HTMLInputElement;
  let preview: HTMLElement;
  let removeButton: HTMLButtonElement;
  let removeCheckbox: HTMLInputElement;

  const createAvatarUpload = (): void => {
    const html = `
      <div data-controller="avatar-preview" data-avatar-preview-initials-value="JD">
        <div data-avatar-preview-target="preview">
          <div class="w-24 h-24 bg-brand-500 rounded-full flex items-center justify-center">
            <span class="text-white text-2xl font-medium">JD</span>
          </div>
        </div>
        <input type="file"
               accept="image/*"
               data-avatar-preview-target="input"
               data-action="change->avatar-preview#preview">
        <input type="hidden"
               name="remove_avatar"
               value="0"
               data-avatar-preview-target="removeCheckbox">
        <button type="button"
                data-avatar-preview-target="removeButton"
                data-action="click->avatar-preview#remove"
                class="hidden">
          Remove
        </button>
      </div>
    `;
    container.innerHTML = html;
    input = container.querySelector('[data-avatar-preview-target="input"]')!;
    preview = container.querySelector('[data-avatar-preview-target="preview"]')!;
    removeButton = container.querySelector('[data-avatar-preview-target="removeButton"]')!;
    removeCheckbox = container.querySelector('[data-avatar-preview-target="removeCheckbox"]')!;
  };

  beforeEach(() => {
    application = Application.start();
    application.register('avatar-preview', AvatarPreviewController);
    container = document.createElement('div');
    document.body.appendChild(container);
    createAvatarUpload();
  });

  afterEach(() => {
    application.stop();
    document.body.removeChild(container);
  });

  describe('preview', () => {
    it('shows image preview when file is selected', (done) => {
      const file = new File(['dummy content'], 'test.png', { type: 'image/png' });

      // Mock the files property on the input
      Object.defineProperty(input, 'files', {
        value: [file],
        writable: false
      });

      // Mock FileReader
      const mockReader = {
        readAsDataURL: jest.fn(),
        onload: null as ((this: FileReader, ev: ProgressEvent<FileReader>) => void) | null,
        result: 'data:image/png;base64,abc123'
      };

      jest.spyOn(window, 'FileReader').mockImplementation(() => mockReader as any);

      // Trigger change event
      input.dispatchEvent(new Event('change', { bubbles: true }));

      // Simulate FileReader onload
      setTimeout(() => {
        if (mockReader.onload) {
          mockReader.onload.call(mockReader as any, {
            target: { result: 'data:image/png;base64,abc123' }
          } as ProgressEvent<FileReader>);
        }

        expect(preview.innerHTML).toContain('img');
        expect(preview.innerHTML).toContain('data:image/png;base64,abc123');
        expect(removeButton).not.toHaveClass('hidden');

        done();
      }, 0);
    });

    it('does not show preview when no file is selected', () => {
      const originalHTML = preview.innerHTML;

      // Mock empty files
      Object.defineProperty(input, 'files', {
        value: [],
        writable: false
      });

      // Trigger change event without files
      input.dispatchEvent(new Event('change', { bubbles: true }));

      expect(preview.innerHTML).toBe(originalHTML);
    });
  });

  describe('remove', () => {
    it('clears file input and shows initials', () => {
      // First add a file
      const file = new File(['dummy content'], 'test.png', { type: 'image/png' });

      // Mock the files property with a file
      Object.defineProperty(input, 'files', {
        value: [file],
        writable: true,
        configurable: true
      });

      expect(input.files?.length).toBe(1);

      // Click remove button
      removeButton.click();

      expect(input.value).toBe('');
      expect(removeCheckbox.value).toBe('1');
      expect(preview.innerHTML).toContain('JD');
      expect(preview.innerHTML).toContain('bg-brand-500');
      expect(removeButton).toHaveClass('hidden');
    });

    it('prevents default event behavior', () => {
      const event = new MouseEvent('click', { bubbles: true, cancelable: true });
      const preventDefaultSpy = jest.spyOn(event, 'preventDefault');

      removeButton.dispatchEvent(event);

      expect(preventDefaultSpy).toHaveBeenCalled();

      preventDefaultSpy.mockRestore();
    });
  });
});
