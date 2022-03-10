angular.module('inprotech.configuration.general.validcombination')
    .factory('validPicklistService', validPicklistService);

function validPicklistService($http) {
    'use strict';
    var service = {
        getPropertyType: getPropertyType,
        getCaseCategory: getCaseCategory
    };

    function getPropertyType(entity) {
        return $http.get('api/picklists/propertyTypes/retrieve/' + entity.propertyTypeModel.code)
            .then(function(propertyType) {
                return propertyType.data;
            });
    }

    function getCaseCategory(entity) {
        return $http.get('api/picklists/caseCategories/' + entity.caseCategoryModel.code + '/' + entity.caseTypeModel.code)
            .then(function(caseCategory) {
                return caseCategory.data;
            });
    }

    return service;
}