angular.module('inprotech.mocks.configuration.search')
    .service('ConfigurationsServiceMock', function() {
        'use strict';

        var r = {
            search: function() {
                return {
                    then: function(cb) {
                        return cb(r.search.returnValue);
                    }
                };
            },
            update: function() {
                return {
                    then: function(cb) {
                        return cb(r.update.returnValue);
                    }
                };
            }
        };

        Object.keys(r).forEach(function(key) {
            if (angular.isFunction(r[key])) {
                spyOn(r, key).and.callThrough();
            }
        });

        return r;
    });