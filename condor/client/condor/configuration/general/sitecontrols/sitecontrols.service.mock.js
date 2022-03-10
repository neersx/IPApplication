angular.module('inprotech.mocks.configuration.general.sitecontrols').service('SiteControlServiceMock', function() {
    'use strict';

    var r = {
        search: function() {
            return {
                then: function(cb) {
                    return cb(r.search.returnValue);
                }
            };
        },
        discard: angular.noop,
        isDirty: function() {
            return r.isDirty.returnValue;
        },
        hasError: function() {
            return r.hasError.returnValue;
        },
        reset: angular.noop,
        save: function() {
            return {
                then: function(cb) {
                    cb(r.save.returnValue);
                    return this;
                }
            };
        },
        getInvalidSiteControls: angular.noop
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

//    return function() {
        return r;
//    };
});
