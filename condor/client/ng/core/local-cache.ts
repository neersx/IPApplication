import { Injectable } from '@angular/core';
import { Storage } from './storage';

export class SessionCache {
    name: string;
    defaultValue: string;
    get: any;
    set: any;
    constructor(defaultValue?: any) {
        this.defaultValue = defaultValue;
    }
}

@Injectable()
export class LocalCache {
    keys = {
        caseView: {
            actions: {
                pageNumber: new SessionCache('20')
            }
        }
    };

    constructor(private readonly store: Storage) {
        this.flatten('', this.keys);
    }

    private readonly flatten = (prefix: string, cache: any) => {
        if (cache instanceof SessionCache) {
            cache.name = prefix;
            cache.get = this.get(cache);
            cache.set = (value: any) => this.set(value, cache);
        } else {
            for (const key in cache) {
                if (cache.hasOwnProperty(key)) {
                    this.flatten(this.getPrefix(prefix, key), cache[key]);
                }
            }
        }
    };

    private readonly getPrefix = (prefixKey: string, property = '') => {
        if (!prefixKey) { return property; }

        return prefixKey + '.' + property;
    };

    private readonly get = (cache: SessionCache): string =>
        this.store.session.get(cache.name) || cache.defaultValue;

    private readonly set = (value: any, cache: SessionCache) =>
            this.store.session.set(cache.name, value);
}
