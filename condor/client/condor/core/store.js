/**
 * A user specific store for storing non-sensitive data in browser.
 * One valid use case could be saving page size for results grid in picklist.
 * It supports persistent storage which relies on HTML5 localStorage.
 * And session storage, which will last until browser is closed.
 * In the future, we can add support for remote storage.
 *
 * Examples:
 * store.local.default('picklist.pageSize', 20)
 * store.local.get('picklist.pageSize')
 * store.local.set('picklist.pageSize', 5)
 * store.session.set('criteria.events.dont-ask-again', true)
 **/
angular.module('inprotech.core').factory('store', function($rootScope) {
    'use strict';

    function getPrefix() {
        return 'inprotech[user=' + $rootScope.appContext.user.name + '].';
    }

    // Fallback to in-memory storage.
    // But it should never happen because the minimum required browers should all support localStorage/sessionStorage.
    function InMemoryStorage() {
        this.items = {};
    }

    _.extend(InMemoryStorage.prototype, {
        setItem: function(key, value) {
            this.items[key] = value;
        },
        getItem: function(key) {
            return this.items[key];
        },
        removeItem: function(key) {
            delete this.items[key];
        }
    });

    function Store(storage, defaults) {
        this._storage = storage;
        this._defaults = defaults;
    }

    _.extend(Store.prototype, {
        setWithoutPrefix: function(key, value) {
            //This function is specifically used for saving setting signin page - before user context is known.
            this._storage.setItem(key, JSON.stringify(value));
        },
        set: function(key, value) {
            this._storage.setItem(getPrefix() + key, JSON.stringify(value));
        },
        get: function(key) {
            var value = this._storage.getItem(getPrefix() + key);

            if (value == null || value === 'undefined') {
                value = this._defaults.getItem(key);
            }

            if (value == null) {
                return value;
            }

            try {
                return JSON.parse(value);
            } catch (e) {
                return this._defaults.getItem(key);
            }
        },
        remove: function(key) {
            this._storage.removeItem(getPrefix() + key);
        },
        default: function(key, value) {
            this._defaults.setItem(key, JSON.stringify(value));
        }
    });

    var hasProvidedConsent = localStorage.getItem('preferenceConsented') === '1';

    return {
        local: new Store(hasProvidedConsent ? window.localStorage : new InMemoryStorage(), new InMemoryStorage()),
        session: new Store(hasProvidedConsent ? window.sessionStorage : new InMemoryStorage(), new InMemoryStorage())
    };
});