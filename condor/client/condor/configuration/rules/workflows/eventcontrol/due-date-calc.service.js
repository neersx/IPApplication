angular.module('inprotech.configuration.rules.workflows').factory('workflowsDueDateCalcService', function($http) {
    'use strict';

    var r = {
        initSettingsViewModel: initSettingsViewModel,
        getSettingsForSave: getSettingsForSave,
        getDueDateCalcs: getDueDateCalcs
    };

    return r;

    function initSettingsViewModel(data) {
        if (data.dateToUse == null) {
            data.dateToUse = 'E';
        }

        if (data.recalcEventDate == null) {
            data.recalcEventDate = false;
        }

        if (data.isSaveDueDate == null) {
            data.isSaveDueDate = false;
        }
        
        if (data.extendDueDate == null) {
            data.extendDueDate = false;
        }

        if (data.extendDueDateOptions == null) {
            data.extendDueDateOptions = {
                type: null,
                value: null
            };
        }

        return data;
    }

    function getSettingsForSave(settings) {
        if (settings.extendDueDate) {
            settings.extendPeriod = settings.extendDueDateOptions.value,
            settings.extendPeriodType = settings.extendDueDateOptions.type
        }
        return settings;
    }

    function getDueDateCalcs(criteriaId, eventId) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/events/' + encodeURIComponent(eventId) + '/duedates')
            .then(function(response) {
                return response.data;
            });
    }
});
