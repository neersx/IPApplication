angular.module('inprotech.mocks.configuration.general.jurisdictions').factory('JurisdictionAttributesServiceMock', function() {
    'use strict';

    var r = {
        listAttributes: function() {
            return {
                then: function(cb) {
                    return cb(r.listAttributes.returnValue);
                }
            };
        },
        getAttributeTypes: function() {
            return {
                then: jasmine.createSpy('getAttributeTypesThen', function(callback) {
                    if (r.getAttributeTypes.returnValue) {
                        return callback(r.getAttributeTypes.returnValue);
                    }
                    return callback({
                        data: {
                            status: 'success'
                        }
                    });

                }).and.callThrough()
            };
        },
        getAttributes: function() {
            return {
                then: jasmine.createSpy('getAttributesThen', function(callback) {
                    if (r.getAttributes.returnValue) {
                        return callback(r.getAttributes.returnValue);
                    }
                    return callback({
                        data: {
                            status: 'success'
                        }
                    });

                }).and.callThrough()
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