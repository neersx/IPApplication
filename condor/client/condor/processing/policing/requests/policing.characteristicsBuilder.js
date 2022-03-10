angular.module('inprotech.processing.policing')
    .factory('policingCharacteristicsBuilder', function() {
        'use strict';

        return {
            build: function(searchCriteria) {
                return {
                    caseType: getKey(searchCriteria, 'caseType', 'code'),
                    jurisdiction: getKey(searchCriteria, 'jurisdiction', 'code'),
                    propertyType: getKey(searchCriteria, 'propertyType', 'code'),
                    action: getKey(searchCriteria, 'action', 'code'),
                    dateOfLaw: getKey(searchCriteria, 'dateOfLaw', 'code'),
                    caseCategory: getKey(searchCriteria, 'caseCategory', 'code'),
                    subType: getKey(searchCriteria, 'subType', 'code'),
                    office: getKey(searchCriteria, 'office', 'key'),
                    caseTypeModel: searchCriteria.caseType,
                    propertyTypeModel: searchCriteria.propertyType,
                    jurisdictionModel: searchCriteria.jurisdiction,
                    caseCategoryModel: searchCriteria.caseCategory
                };
            }
        };

        function getKey(searchCriteria, propertyName, key) {
            return searchCriteria[propertyName] && searchCriteria[propertyName][key];
        }
    });