angular.module('inprotech.configuration.general.validcombination')
    .factory('validCombinationService', ValidCombinationService);



function ValidCombinationService($http, menuSelection, utils) {
    'use strict';

    var service = {
        baseUrl: 'api/configuration/validcombination/',
        search: search,
        exportToExcel: exportToExcel,
        add: add,
        update: update,
        delete: deleteSelected,
        get: getSelectedEntity,
        validActions: validActions,
        copy: copyValidCombination,
        updateActionSequence: updateActionSequence,
        validateCategory: validateCategory,
        getDefaultCountry: getDefaultCountry
    };

    var preRequest = utils.cancellable();

    return service;

    var lastSearchCriteria;
    var lastQueryParams;
    var lastSearchType;

    function search(searchCriteria, queryParams, searchType) {
        lastSearchCriteria = searchCriteria;
        lastQueryParams = queryParams;
        lastSearchType = searchType;

        var apiUrl = service.baseUrl + searchType + '/search';

        return $http.get(apiUrl, {
                params: {
                    criteria: JSON.stringify(searchCriteria),
                    params: queryParams
                }
            })
            .then(function(response) {
                menuSelection.update(searchType, response.data.data.length, 0);
                return response.data;
            });
    }

    function exportToExcel() {
        var apiUrl = service.baseUrl + lastSearchType + '/exportToExcel';
        window.location = apiUrl + '?criteria=' + JSON.stringify(lastSearchCriteria) + '&params=' + JSON.stringify(lastQueryParams);
    }

    function validActions(searchType, filterCriteria) {
        var apiUrl = service.baseUrl + searchType + '/validactions';

        return $http.get(apiUrl, {
            params: {
                criteria: JSON.stringify(filterCriteria)
            }
        });
    }

    function resolveUrl(characteristic) {
        return service.baseUrl + characteristic.type;
    }

    function add(entity, characteristic) {
        var apiUrl = resolveUrl(characteristic);
        return $http.post(apiUrl, entity);
    }

    function update(entity, characteristic) {
        var apiUrl = resolveUrl(characteristic);
        return $http.put(apiUrl, entity);
    }

    function deleteSelected(entityKeys, characteristic) {
        var selectedKeys = JSON.stringify(entityKeys);
        return $http.post(resolveUrl(characteristic) + '/delete', selectedKeys);
    }

    function getSelectedEntity(entityKey, characteristic) {
        return $http.get(resolveUrl(characteristic), {
                params: {
                    entitykey: JSON.stringify(entityKey)
                }
            })
            .then(function(response) {
                return response.data;
            });
    }

    function copyValidCombination(copyEntity) {
        return $http.post(service.baseUrl + 'copy', copyEntity);
    }

    function updateActionSequence(saveDetail) {
        var apiUrl = service.baseUrl + 'action/updateactionsequence';
        return $http.post(apiUrl, saveDetail);
    }

    function validateCategory(caseType, caseCategory, characteristic) {
        preRequest.cancel();
        return $http.get(service.baseUrl + characteristic + '/validateCategory', {
                params: {
                    caseType: caseType,
                    caseCategory: caseCategory
                },
                timeout: preRequest.promise
            })
            .then(function(response) {
                return response.data.result;
            });
    }

    function getDefaultCountry() {
        return $http.get('api/picklists/jurisdictions/ZZZ')
            .then(function(response) {
                return response.data.data;
            });
    }

}