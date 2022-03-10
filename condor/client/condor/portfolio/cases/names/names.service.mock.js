angular.module('inprotech.mocks.portfolio.cases')
    .service('caseviewNamesServiceMock', function() {
        'use strict';

        var r = {
            getNames: function() {
                return {
                    then: function(cb) {
                        return cb(r.getNames.returnValue);
                    }
                };
            },
            getFirstEmailTemplate: function() {
                return {
                    then: function(cb) {
                        return cb(r.getFirstEmailTemplate.returnValue);
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