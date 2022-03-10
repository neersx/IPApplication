angular.module('inprotech.configuration.rules.workflows').factory('workflowsMaintenanceService', function($http, workflowsCharacteristicsService) {
    'use strict';
    var charsService = workflowsCharacteristicsService;
    var appliesToOptions = [{
        value: true,
        label: 'workflows.common.localOrForeignDropdown.localClients'
    }, {
        value: false,
        label: 'workflows.common.localOrForeignDropdown.foreignClients'
    }];

    // must be singleton
    return {
        create: create,
        save: save,
        getCharacteristics: getCharacteristics,
        picklistEquals: picklistEquals,
        createSaveRequestDataForCharacteristics: createSaveRequestDataForCharacteristics,
        appliesToOptions: appliesToOptions,
        getParent: getParent,
        getDescendants: getDescendants,
        resetWorkflow: resetWorkflow
    };

    function getCharacteristics(criteriaId) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/characteristics').then(function(response) {
            return response.data;
        });
    }

    function create(formData) {
        return $http.post('api/configuration/rules/workflows', formData);
    }

    function save(criteriaId, formData) {
        return $http.put('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId), formData);
    }

    function picklistEquals(propName, newVal, oldVal) {
        if (charsService.isCharacteristicField(propName)) {
            return compare(newVal, oldVal, 'key');
        }
    }

    function getParent(criteriaId) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/parent').then(function(response) {
            return response.data;
        });
    }

    function getDescendants(criteriaId) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/descendants')
            .then(function(response) {
                return response.data;
            });
    }

    function resetWorkflow(criteriaId, applyToDescendants, updateDueDate) {
        return $http.put('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/reset?applyToDescendants=' + encodeURIComponent(applyToDescendants) +
                (updateDueDate != null ? '&updateRespNameOnCases=' + encodeURIComponent(updateDueDate) : ''))
            .then(function(response) {
                return response.data;
            });
    }

    function createSaveRequestDataForCharacteristics(formData) {
        var results = _.extend({}, formData);

        _.each(charsService.characteristicFields, function(field) {
            if (formData[field] && formData[field].key) {
                results[field] = formData[field].key;
            } else {
                results[field] = null;
            }
        });

        var fields = ['caseCategory', 'propertyType', 'caseType', 'action', 'subType', 'basis', 'jurisdiction', 'dateOfLaw'];
        _.each(fields, function(field) {
            if (formData[field] && formData[field].code) {
                results[field] = formData[field].code;
            } else {
                results[field] = null;
            }
        });

        return results;
    }

    function compare(itemA, itemB, key) {
        itemA = itemA == null || itemA[key] == null ? null : itemA;
        itemB = itemB == null || itemB[key] == null ? null : itemB;

        if (itemA === itemB) {
            return true;
        }

        if (itemA == null) {
            return itemB == null;
        }

        if (itemB == null) {
            return itemA == null;
        }

        return itemA[key] === itemB[key];
    }
});