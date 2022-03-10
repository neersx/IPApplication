angular.module('inprotech.configuration.general.jurisdictions').factory('jurisdictionMaintenanceService', function($http) {
    'use strict';
    var baseUrl = 'api/configuration/jurisdictions/maintenance/';

    function equals(v1, v2) {
        if (v1 && v1.key && v2 && v2.key) {
            return equals(v1.key, v2.key);
        }

        if (v2 instanceof Date) {
            v1 = new Date(v1);
        }

        return normalize(v1) === normalize(v2);
    }

    function normalize(value) {
        if (value === '' || value == null) {
            return null;
        }

        if (value instanceof Date) {
            return Number(value);
        }

        return value;
    }

    var service = {
        save: function(id, data) {
            return $http.put(baseUrl + id, data);
        },
        create: function(data) {
            return $http.post(baseUrl, data);
        },
        delete: function(ids) {
            return $http.post(baseUrl + 'delete/', ids);
        },
        isDuplicated: function(allRecords, currentRecord, propList) {
            var exists = _.any(_.without(allRecords, currentRecord), function(r) {
                return _.all(propList, function(p) {
                    return equals(r[p], currentRecord[p]);
                });
            });

            return exists;
        },
        saveResponse: null,
        getInUseItems: getInUseItems,
        changeJurisdictionCode: changeJurisdictionCode
    };

    function changeJurisdictionCode(entity) {
        return $http.post("api/configuration/jurisdictions/maintenance/changecode", entity);
    }

    function getInUseItems(topicKey) {
        if (service.saveResponse === null)
            return null;
        var saveResponseForTopic = _.first(_.where(service.saveResponse, {
            topicName: topicKey
        }));
        if (saveResponseForTopic !== undefined) {
            return saveResponseForTopic.inUseItems;
        }
        return null;
    }

    return service;
});