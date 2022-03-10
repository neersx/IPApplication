angular.module('inprotech.configuration.rules.workflows').factory('workflowInheritanceService', function($http) {
    'use strict';

    var r = {
        breakInheritance: breakInheritance,
        getCriteriaDetail: getCriteriaDetail,
        changeParentInheritance: changeParentInheritance,
        deleteCriteria: deleteCriteria,
        isCriteriaUsedByCase: isCriteriaUsedByCase
    };

    return r;

    function changeParentInheritance(criteriaId, newParentId, replaceCommonRules) {
        return $http.put('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/inheritance', {
            newParent: newParentId,
            replaceCommonRules: replaceCommonRules
        }).then(function(response){
            return response.data;
        });
    }

    function breakInheritance(criteriaId) {
        return $http.delete('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/inheritance');
    }

    function deleteCriteria(criteriaId) {
        return $http.delete('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId));
    }

    function isCriteriaUsedByCase(criteriaId){
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/usedByCase').then(function(response){
            return response.data;
        });
    }

    function getCriteriaDetail(criteriaId) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/characteristics').then(function(response) {
            var data = response.data;
            return {
                office: data.office.value,
                jurisdiction: data.jurisdiction.value,
                caseType: data.caseType.value,
                propertyType: data.propertyType.value,
                caseCategory: data.caseCategory.value,
                subType: data.subType.value,
                basis: data.basis.value,
                dateOfLaw: data.dateOfLaw.value,
                action: data.action.value,
                localOrClient: data.isLocalClient == null ? '' : (data.isLocalClient ? 'Local clients' : 'Foreign clients'),
                inUse: data.inUse,
                isProtected: data.isProtected
            };
        });
    }
});
