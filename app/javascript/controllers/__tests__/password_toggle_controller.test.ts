import { Application } from '@hotwired/stimulus';
import PasswordToggleController from '../password_toggle_controller';

describe('PasswordToggleController', () => {
  let application: Application;
  let container: HTMLDivElement;
  let input: HTMLInputElement;
  let icon: HTMLElement;

  const createPasswordField = (): void => {
    const html = `
      <div data-controller="password-toggle">
        <input type="password" data-password-toggle-target="input" value="secret123">
        <button type="button" data-action="click->password-toggle#toggle">
          <i class="fas fa-eye" data-password-toggle-target="icon"></i>
        </button>
      </div>
    `;
    container.innerHTML = html;
    input = container.querySelector('input')!;
    icon = container.querySelector('i')!;
  };

  beforeEach(() => {
    application = Application.start();
    application.register('password-toggle', PasswordToggleController);
    container = document.createElement('div');
    document.body.appendChild(container);
    createPasswordField();
  });

  afterEach(() => {
    application.stop();
    document.body.removeChild(container);
  });

  describe('toggle', () => {
    it('changes password input to text and updates icon', () => {
      expect(input.type).toBe('password');
      expect(icon).toHaveClass('fa-eye');
      expect(icon).not.toHaveClass('fa-eye-slash');

      const button = container.querySelector('button')!;
      button.click();

      expect(input.type).toBe('text');
      expect(icon).not.toHaveClass('fa-eye');
      expect(icon).toHaveClass('fa-eye-slash');
    });

    it('changes text input back to password and updates icon', () => {
      const button = container.querySelector('button')!;

      // First toggle to text
      button.click();
      expect(input.type).toBe('text');
      expect(icon).toHaveClass('fa-eye-slash');

      // Toggle back to password
      button.click();
      expect(input.type).toBe('password');
      expect(icon).toHaveClass('fa-eye');
      expect(icon).not.toHaveClass('fa-eye-slash');
    });

    it('preserves input value when toggling', () => {
      const button = container.querySelector('button')!;

      expect(input.value).toBe('secret123');

      button.click();
      expect(input.value).toBe('secret123');

      button.click();
      expect(input.value).toBe('secret123');
    });
  });
});
