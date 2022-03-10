angular.module('inprotech.mocks.portfolio.cases')
    .service('caseViewCaseTextsServiceMock', function() {
        'use strict';

        var r = {
            getTexts: function() {
                return {
                    then: function(cb) {
                        return cb(r.getTexts.returnValue);
                    }
                };
            },
            getTextHistory: function() {
                return {
                    then: function(cb) {
                        return cb(r.getTextHistory.returnValue);
                    }
                }
            }
        };

        Object.keys(r).forEach(function(key) {
            if (angular.isFunction(r[key])) {
                spyOn(r, key).and.callThrough();
            }
        });

        return r;
    });