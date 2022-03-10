angular.module('inprotech.mocks.configuration.rules.workflows').factory('workflowsSearchServiceMock', function() {
    'use strict';

    var r = {
        search: function() {
            return {
                then: function(cb) {
                    return cb(r.search.returnValue);
                }
            };
        },
        searchByIds: function() {
            return {
                then: function(cb) {
                    return cb(r.searchByIds.returnValue);
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
        getDefaultDateOfLaw: function() {
            return {
                then: function(cb) {
                    return cb(r.getDefaultDateOfLaw.returnValue);
                }
            };
        },
        getCaseCharacteristics: function() {
            return {
                then: function(cb) {
                    return cb(r.getCaseCharacteristics.returnValue);
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
