angular.module('inprotech.mocks.configuration.general.jurisdictions').factory('JurisdictionMaintenanceServiceMock', function() {
    'use strict';

    var r = {
        search: function() {
            return {
                then: function(cb) {
                    return cb(r.search.returnValue);
                }
            };
        },
        save: function() {
            return {
                then: function(cb) {
                    var response = {
                        data: {
                            result: {}
                        }
                    };
                    response.data = {
                        result: 'success'
                    };
                    return cb(response);
                }
            };
        },
        create: function() {
            return {
                then: function(cb) {
                    cb(r.create.returnValue);
                    return this;
                }
            };
        },
        delete: function() {
            return {
                then: function(cb) {
                    cb(r.create.returnValue);
                    return this;
                }
            };
        },
        isDuplicated: _.constant(false),
        changeJurisdictionCode: function() {
            return {
                then: function(cb) {
                    var response = { data: {} };
                    response.data.result = 'success';
                    return cb(response);
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