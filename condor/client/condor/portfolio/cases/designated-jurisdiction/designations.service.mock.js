angular.module('inprotech.mocks.portfolio.cases')
    .service('caseViewDesignationsServiceMock', function() {
        'use strict';

        var r = {
            getCaseViewDesignatedJurisdictions: function() {
                return {
                    then: function(cb) {
                        return cb(r.getCaseViewDesignatedJurisdictions.returnValue);
                    }
                };
            },
            getColumnFilterData: function() {
                return {
                    then: function(cb) {
                        return cb(r.getColumnFilterData.returnValue);
                    }
                };
            },
            getSummary: function() {
                return {
                    then: function(cb) {
                        return cb(r.getSummary.returnValue);
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