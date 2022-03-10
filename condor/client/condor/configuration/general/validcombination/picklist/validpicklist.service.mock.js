angular.module('inprotech.mocks.configuration.validcombination').factory('validPicklistServiceMock', function() {
    'use strict';

    var r = {
        baseUrl: 'api/configuration/validcombination/',
        getPropertyType: function(entity) {
            return {
                then: function(cb) {
                    return cb({
                        key: entity.propertyTypeModel.key,
                        code: 'P',
                        value: 'Patents'
                    });
                }
            };
        },
        getCaseCategory: function(entity) {
            return {
                then: function(cb) {
                    return cb({
                        key: 1,
                        code: entity.caseCategoryModel.code,
                        value: 'Patents'
                    });
                }
            };
        }
    };
    return r;
});
