angular.module('inprotech.mocks.portfolio.cases')
    .service('debtorRestrictionsServiceMock', function() {
        'use strict';

        var r = {
            getRestrictions: function() {
                return {
                    then: function(cb) {
                        return cb(r.getRestrictions.returnValue);
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