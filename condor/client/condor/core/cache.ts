'use strict';
namespace inprotech.core {
    export class SessionCache {
        public name: String;
        public defaultValue: any;
        public get: any;
        public set: any;
        constructor(defaultValue?: any) {
            this.defaultValue = defaultValue;
        }
    }

    export class LocalCache {

        // expand the keys for any new store
        public Keys = {
            debtorRestrictionStatus: {
                debtors: new SessionCache({})
            }
        }

        constructor(private store: any) {
            this.flatten(null, this.Keys);
        }

        private flatten = (prefix: string, cache: any) => {
            if (cache instanceof SessionCache) {
                cache.name = prefix;
                cache.get = this.get(cache);
                cache.set = (value) => {
                    this.set(value, cache);
                };
            } else {
                for (let key in cache) {
                    if (cache.hasOwnProperty(key)) {
                        this.flatten(this.getPrefix(prefix, key), cache[key]);
                    }
                }
            }
        }

        private getPrefix = (prefixKey: string, property = '') => {
            if (!prefixKey) { return property; }
            return prefixKey + '.' + property;
        }

        private get(cache): any {
            return this.store.session.get(cache.name) || cache.defaultValue;
        }

        private set(value, cache) {
            this.store.session.set(cache.name, value);
        }
    }

    angular.module('inprotech.core').service('localCache', ['store', LocalCache]);
}