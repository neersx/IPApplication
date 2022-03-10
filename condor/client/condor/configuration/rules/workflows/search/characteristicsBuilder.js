angular.module('inprotech.configuration.rules.workflows').factory('characteristicsBuilder', function() {
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
                basis: getKey(searchCriteria, 'basis', 'code'),
                office: getKey(searchCriteria, 'office', 'key'),
                applyTo: searchCriteria.applyTo,
                matchType: searchCriteria.matchType,
                includeProtectedCriteria: searchCriteria.includeProtectedCriteria,
                includeCriteriaNotInUse: searchCriteria.includeCriteriaNotInUse,
                event: getKey(searchCriteria, 'event', 'key'),
                eventSearchType: searchCriteria.eventSearchType,
                examinationType: getKey(searchCriteria, 'examinationType', 'key'),
                renewalType: getKey(searchCriteria, 'renewalType', 'key')
            };
        }
    };

    function getKey(searchCriteria, propertyName, key) {
        return searchCriteria[propertyName] && searchCriteria[propertyName][key];
    }
});