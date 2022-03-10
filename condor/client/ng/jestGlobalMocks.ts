import { Pipe, PipeTransform, Component, EventEmitter, Directive } from "@angular/core";

if (!(window as any).angular) {
  (window as any).angular = {};
}

Object.defineProperty(window, 'CSS', { value: null });
// Object.defineProperty(window, 'localStorage', { value: createStorageMock() });
// Object.defineProperty(window, 'sessionStorage', { value: createStorageMock() });
Object.defineProperty(document, 'doctype', {
  value: '<!DOCTYPE html>'
});
Object.defineProperty(window, 'getComputedStyle', {
  value: () => {
    return {
      display: 'none',
      appearance: ['-webkit-appearance']
    };
  }
});
/**
 * ISSUE: https://github.com/angular/material2/issues/7101
 * Workaround for JSDOM missing transform property
 */
Object.defineProperty(document.body.style, 'transform', {
  value: () => {
    return {
      enumerable: true,
      configurable: true,
    };
  },
});
Object.defineProperty(window, 'getComputedStyle', {
  value: () => ({
    getPropertyValue: (prop) => {
      return '';
    }
  })
});

const MockStorage = () => {
  let storage = {};
  return {
    getItem: (key: string) => key in storage ? storage[key] : null,
    setItem: (key: string | number, value: string) => storage[key] = value || '',
    removeItem: (key: string | number) => delete storage[key],
    clear: () => storage = {},
  };
};

export function MockPipe(name: string, transform?: any): Pipe {
  class Mock implements PipeTransform {
    transform = transform || (() => undefined);
  }

  return Pipe({ name })(Mock as any);
}

export function MockComponent(selector: string, options: Component = {}): Component {
  const metadata: Component = {
    selector,
    template: options.template || '',
    inputs: options.inputs || [],
    outputs: options.outputs || [],
    exportAs: options.exportAs || ''
  };

  class Mock {
    constructor() {
      metadata.outputs.forEach(method => {
        this[method] = new EventEmitter<any>();
      });
    }
  }

  return Component(metadata)(Mock as any);
}

export function MockDirective(selector: string, options: Directive = {}): Directive {

  const metadata: Directive = {
    selector,
    inputs: options.inputs || [],
    outputs: options.outputs || [],
    providers: options.providers || [],
    exportAs: options.exportAs || ''
  };

  class Mock {
    constructor() {
      metadata.outputs.forEach(method => {
        this[method] = new EventEmitter<any>();
      });
    }
  }

  return Directive(metadata)(Mock as any);
}

