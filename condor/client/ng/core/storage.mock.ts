import { Injectable } from '@angular/core';
import { InMmeoryDataStore } from './data-store';
import { Storage } from './storage';

@Injectable()
export class StorageMock extends Storage {
    constructor() {
        localStorage.setItem('preferenceConsented', '1');
        const local = new InMmeoryDataStore();
        const session = new InMmeoryDataStore();
        super(local, session);

        this.spyOn(this.local);
        this.spyOn(this.session);
    }

    spyOn(store): void {
        jest.spyOn(store, 'set');
        jest.spyOn(store, 'get');
        jest.spyOn(store, 'remove');
    }
}
