angular.module('inprotech.configuration.rules.workflows').factory('workflowsEntryControlService', function($http) {
    'use strict';

    var dateOptions = [{
        key: 0,
        value: 'workflows.entrycontrol.dateOptions.displayOnly'
    }, {
        key: 1,
        value: 'workflows.entrycontrol.dateOptions.entryMandatory'
    }, {
        key: 2,
        value: 'workflows.entrycontrol.dateOptions.hide'
    }, {
        key: 3,
        value: 'workflows.entrycontrol.dateOptions.entryOptional'
    }, {
        key: 4,
        value: 'workflows.entrycontrol.dateOptions.defaultToSystemDate'
    }];
    var dateOptionsMap = _.object(_.map(dateOptions, function(item) {
        return [item.key, item.value];
    }));

    var controlOptions = [{
        key: 0,
        value: 'workflows.entrycontrol.controlOptions.displayOnly'
    }, {
        key: 1,
        value: 'workflows.entrycontrol.controlOptions.entryMandatory'
    }, {
        key: 2,
        value: 'workflows.entrycontrol.controlOptions.hide'
    }, {
        key: 3,
        value: 'workflows.entrycontrol.controlOptions.entryOptional'
    }];
    var controlOptionsMap = _.object(_.map(controlOptions, function(item) {
        return [item.key, item.value];
    }));

    var dueDateRespOptions = function() {
        return _.filter(controlOptions, function(option) {
            return option.key == 0 || option.key == 1 || option.key == 3
        });
    }

    function getDetails(criteriaId, entryId) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/entrycontrol/' + encodeURIComponent(entryId) + '/details')
            .then(function(response) {
                return response.data;
            });
    }

    function getDocuments(criteriaId, entryId) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/entrycontrol/' + encodeURIComponent(entryId) + '/documents')
            .then(function(response) {
                return response.data;
            });
    }

    function translateDateOption(option) {
        if (option == null) {
            return '';
        }

        return dateOptionsMap[option];
    }

    function translateControlOption(option) {
        if (option == null) {
            return '';
        }

        return controlOptionsMap[option];
    }

    function getSteps(criteriaId, entryId) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/entrycontrol/' + encodeURIComponent(entryId) + '/steps')
            .then(function(response) {
                return response.data;
            });
    }

    function updateDetail(criteriaId, entryId, formData) {
        return $http.put('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/entrycontrol/' + encodeURIComponent(entryId), formData)
    }

    function isDuplicated(allRecords, currentRecord, propList) {
        var exists = _.any(allRecords, function(r) {
            return _.all(propList, function(p) {
                return equals(r[p], currentRecord[p]);
            });
        });

        return exists;
    }

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

    function isApplyDisabled(angularForm) {
        return angularForm.$pristine || angularForm.$invalid;
    }

    function isApplyEnabled(angularForm) {
        return !angularForm.$pristine && !angularForm.$invalid;
    }

    function getDescendants(criteriaId, entryId, newEntryDescription) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/entrycontrol/' +
            encodeURIComponent(entryId) + '/descendants?newEntryDescription=' + encodeURIComponent(newEntryDescription));
    }

    function getDescendantsAndParentWithInheritedEntry(criteriaId, entryId) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/entrycontrol/' + encodeURIComponent(entryId) + '/descendants/parent')
            .then(function(response) {
                return response.data;
            });
    }

    function resetEntry(criteriaId, entryId, appliesToDescendants) {
        return $http.post('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/entrycontrol/' + encodeURIComponent(entryId) + '/reset?appliesToDescendants=' + appliesToDescendants);
    }

    function breakEntryInheritance(criteriaId, entryId) {
        return $http.post('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/entrycontrol/' + encodeURIComponent(entryId) + '/break');
    }

    function setEditedAddedFlags(data, isEditMode) {
        if (isEditMode && !data.isAdded) {
            data.isEdited = true;
            data.inherited = false;
        } else {
            data.isAdded = true;
        }
    }

    function getUserAccess(criteriaId, entryId) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/entrycontrol/' + encodeURIComponent(entryId) + '/useraccess')
            .then(function(response) {
                return response.data;
            });
    }

    function getUsers(roleId) {
        return $http.get('api/configuration/roles/' + encodeURIComponent(roleId) + '/users')
            .then(function(response) {
                return response.data;
            });
    }

    var service = {
        getDetails: getDetails,
        getDocuments: getDocuments,
        translateDateOption: translateDateOption,
        translateControlOption: translateControlOption,
        getSteps: getSteps,
        updateDetail: updateDetail,
        dateOptions: dateOptions,
        controlOptions: controlOptions,
        dueDateRespOptions: dueDateRespOptions,
        isApplyDisabled: isApplyDisabled,
        isApplyEnabled: isApplyEnabled,
        isDuplicated: isDuplicated,
        getDescendants: getDescendants,
        resetEntry: resetEntry,
        breakEntryInheritance: breakEntryInheritance,
        getDescendantsAndParentWithInheritedEntry: getDescendantsAndParentWithInheritedEntry,
        setEditedAddedFlags: setEditedAddedFlags,
        getUserAccess: getUserAccess,
        getUsers: getUsers
    };
    return service;
});