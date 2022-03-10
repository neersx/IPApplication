import { any } from '@uirouter/core';

export class WindowRefMock {
    _window: any;
    nativeWindow: Window;
    constructor(window: any = null) {
        this.nativeWindow = window || { parent: { postMessage: jest.fn() }, open: jest.fn() } as any;
    }
}