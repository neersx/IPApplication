export interface DataStore {
    get(key: string): any;
    remove(key: string): void;
    set(key: string, value: any): void;
}

export class LocalDataStore implements DataStore {
    // tslint:disable-next-line: no-unbound-method
    get = (key: string) => {
        const val = localStorage.getItem(key);
        if (val) {
            return JSON.parse(val);
        }

        return val;
    };
    // tslint:disable-next-line: no-unbound-method
    set = (key: string, value: any) => {
        if (value != null) {
            localStorage.setItem(key, JSON.stringify(value));
        } else {
            localStorage.setItem(key, null);
        }
    };
    // tslint:disable-next-line: no-unbound-method
    remove = (key: any) => localStorage.removeItem(key);
}

export class SessionDataStore implements DataStore {
    // tslint:disable-next-line: no-unbound-method
    // tslint:disable-next-line: no-unbound-method
    get = (key: string) => {
        const val = sessionStorage.getItem(key);
        if (val) {
            return JSON.parse(val);
        }

        return val;
    };
    // tslint:disable-next-line: no-unbound-method
    set = (key: string, value: any) => {
        if (value != null) {
            sessionStorage.setItem(key, JSON.stringify(value));
        } else {
            sessionStorage.setItem(key, null);
        }
    };
    // tslint:disable-next-line: no-unbound-method
    remove = (key: any) => sessionStorage.removeItem(key);
}

export class InMmeoryDataStore implements DataStore {
    private readonly items = {};

    get(key: string): any {
        return this.items[key];
    }

    remove(key: string): void {
        // tslint:disable-next-line: no-dynamic-delete
        delete this.items[key];
    }

    set(key: string, value: any): void {
        this.items[key] = value;
    }
}