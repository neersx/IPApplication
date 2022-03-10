angular.module('inprotech.mocks.configuration.validcombination').factory('ValidCombinationServiceMock', function() {
    'use strict';

    var r = {
        baseUrl: 'api/configuration/validcombination/',
        search: function() {
            return {
                then: function(cb) {
                    return cb(r.search.returnValue);
                }
            };
        },
        get: function(entityId) {
            return {
                then: function(cb) {
                    return cb({
                        id: entityId
                    });
                }
            };
        },
        add: function() {
            return {
                then: function(cb) {
                    var response = {
                        data: {
                            result: {}
                        }
                    };
                    response.data.result = {
                        result: 'success',
                        updatedKeys: {
                            countryId: '1',
                            propertyTypeId: '1'
                        }
                    };
                    return cb(response);
                }
            };
        },
        update: function() {
            return {
                then: function(cb) {
                    var response = {
                        data: {
                            result: {}
                        }
                    };
                    response.data.result = {
                        result: 'success',
                        updatedKeys: {
                            countryId: '1',
                            propertyTypeId: '1'
                        }
                    };
                    return cb(response);
                }
            };
        },
        delete: function() {
            return {
                then: function(cb) {
                    var response = {
                        data: {
                            message: 'delete successful'
                        }
                    };
                    return cb(response);
                }
            };
        },
        validateCopy: function() {
            return {
                then: function(cb) {
                    var response = {
                        result: null
                    };
                    return cb(response);
                }
            };
        },
        copy: function() {
            return {
                then: function(cb) {
                    var response = {
                        data: {
                            result: {}
                        }
                    };
                    response.data.result = {
                        result: 'success'
                    };
                    return cb(response);
                }
            };
        },
        validateCategory: function() {
            return {
                then: function(cb) {
                    return cb(r.validateCategory.returnValue);
                }
            };
        },
        getDefaultCountry: function() {
            return {
                then: function(cb) {
                    var response = {
                        data: {
                            data: {key: 'ZZZ', code: 'ZZZ', value: 'DEFAULT FOREIGN COUNTRY'}
                        }
                    };
                    return cb(response);
                }
            };
        }
    };
    return r;
});
