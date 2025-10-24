import '@testing-library/jest-dom';

// Mock HTMLDialogElement methods that aren't supported in jsdom
HTMLDialogElement.prototype.showModal = jest.fn(function(this: HTMLDialogElement) {
  this.open = true;
});

HTMLDialogElement.prototype.close = jest.fn(function(this: HTMLDialogElement) {
  this.open = false;
});

// Mock DataTransfer for file upload tests
if (typeof DataTransfer === 'undefined') {
  (global as any).DataTransfer = class DataTransfer {
    items: { add: (file: File) => void };
    files!: FileList;

    constructor() {
      const files: File[] = [];
      this.items = {
        add: (file: File) => {
          files.push(file);
        }
      };
      Object.defineProperty(this, 'files', {
        get: () => {
          const fileList: any = files;
          fileList.item = (index: number) => files[index];
          return fileList as FileList;
        }
      });
    }
  };
}
