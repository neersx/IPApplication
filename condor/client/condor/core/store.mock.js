angular.module('inprotech.mocks.core').factory('storeMock', function() {
    'use strict';

    var r = {
        local: {
            get: function() {
                return r.local.get.returnValue;
            },
            setWithoutPrefix: function() {
                return;
            },
            set: function(key, value) {
                r.local.get.returnValue = value;
            },
            default: function() {
                return r.local.default.returnValue;
            },
            remove: function() {
                r.local.get.returnValue = undefined;
                return;
            }
        },
        session: {
            get: function() {
                return r.session.get.returnValue;
            },
            set: function(key, value) {
                r.session.get.returnValue = value;
            },
            default: function() {
                return r.session.default.returnValue;
            }
        }
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        } else {
            if (Object.keys(r[key]).length > 0) {
                Object.keys(r[key]).forEach(function(key1) {
                    if (angular.isFunction(r[key][key1])) {
                        spyOn(r[key], key1).and.callThrough();
                    }
                });
            }
        }
    });

    return r;
});