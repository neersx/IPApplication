angular.module('inprotech.mocks.configuration.rules.workflows').factory('workflowInheritanceServiceMock', function() {
    'use strict';

    var r = {
        breakInheritance: function() {
            return {
                then: function(cb) {
                    return cb(r.breakInheritance.returnValue);
                }
            };
        },
        getCriteriaDetail: function() {
            return {
                then: function(cb) {
                    return cb(r.getCriteriaDetail.returnValue);
                }
            };
        },
        changeParentInheritance: function() {
            return {
                then: function(cb) {
                    return cb(r.changeParentInheritance.returnValue);
                }
            };
        },
        deleteCriteria: function() {
            return {
                then: function(cb) {
                    return cb();
                }
            };
        },
        isCriteriaUsedByCase: function() {
            return {
                then: function(cb) {
                    return cb(r.isCriteriaUsedByCase.returnValue);
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
