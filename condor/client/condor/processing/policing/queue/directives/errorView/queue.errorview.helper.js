angular.module('inprotech.processing.policing').factory('queueErrorViewHelper', function () {
    'use strict';

    var vm = this;
    vm.$onInit = onInit;

    function onInit() {
        vm.combinedFieldTemplate = combinedFieldTemplate;
    }

    function getColumns(permissions) {
        return [{
            title: 'policing.queue.errors.date',
            field: 'errorDate',
            sortable: false,
            width: '100px',
            template: '<ip-date-time model="dataItem.errorDate"></ip-date-time>'
        }, {
            title: 'policing.queue.errors.message',
            field: 'message',
            sortable: false,
            width: '150px'
        }, {
            title: 'policing.queue.errors.event',
            sortable: false,
            width: '150px',
            template: function (dataItem) {
                if (permissions.canMaintainWorkflow && dataItem.hasEventControl) {
                    return '<a href="#/configuration/rules/workflows/' + dataItem.eventCriteriaNumber + '/eventcontrol/' + dataItem.eventNumber + '">{{vm.combinedFieldTemplate(dataItem.eventDescription, dataItem.eventNumber)}}</a>';
                } else {
                    return '<span ng-if="dataItem.eventNumber">{{ vm.combinedFieldTemplate(dataItem.eventDescription, dataItem.eventNumber)}}</span>';
                }
            }
        }, {
            title: 'policing.queue.errors.cycle',
            field: 'eventCycle',
            sortable: false,
            width: '60px'
        }, {
            title: 'policing.queue.errors.criteria',
            sortable: false,
            width: '150px',
            template: function (dataItem) {
                if (permissions.canMaintainWorkflow) {
                    return '<a ng-if="dataItem.eventCriteriaNumber" href="#/configuration/rules/workflows/' + dataItem.eventCriteriaNumber + '">' + combinedFieldTemplate(dataItem.criteriaDescription, dataItem.eventCriteriaNumber) + '</a>';
                } else {
                    return '<span ng-if="dataItem.eventCriteriaNumber">' + combinedFieldTemplate(dataItem.criteriaDescription, dataItem.eventCriteriaNumber) + '</span>';
                }
            }
        }];
    }

    function combinedFieldTemplate(fieldValue, fieldInBrackets) {
        if (fieldValue && fieldInBrackets)
            return fieldValue + " (" + fieldInBrackets + ")";
        if (fieldValue)
            return fieldValue;
        if (fieldInBrackets)
            return fieldInBrackets
        return "";
    }

    return {
        buildOptionsForPolicingError: function (kendoGridBuilder, scope, gridParams) {
            return kendoGridBuilder.buildOptions(scope, {
                id: gridParams.id,
                pageable: gridParams.pageable,
                resizable: gridParams.resizable,
                scrollable: gridParams.scrollable,
                autoBind: true,
                noRecords: true,
                reorderable: false,
                read: gridParams.read,
                columns: getColumns(gridParams.permissions),
                navigatable: true,
                selectable: true
            });
        }
    };
});
