angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlDesignatedJurisdictions', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/designated-jurisdictions.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function ($scope, kendoGridBuilder, workflowsEventControlService, picklistService, kendoGridService) {
        'use strict';

        var vm = this;
        var service;
        var viewData;
        vm.$onInit = onInit;

        function onInit() {
            service = workflowsEventControlService;
            viewData = vm.topic.params.viewData;

            vm.topic.validate = validate;
            vm.topic.hasError = hasError;
            vm.topic.isDirty = isDirty;
            vm.topic.getFormData = getFormData;

            vm.canEdit = viewData.canEdit;
            vm.selectedCountryFlag = viewData.designatedJurisdictions.countryFlagForStopReminders;
            vm.countryFlags = viewData.designatedJurisdictions.countryFlags;
            vm.onAddClick = selectJurisdictions;
            vm.groupName = viewData.characteristics.jurisdiction.value;
            vm.groupKey = viewData.characteristics.jurisdiction.key;

            vm.parentData = (viewData.isInherited === true && viewData.parent) ? viewData.parent.designatedJurisdictions : {};

            vm.gridOptions = buildGridOptions();
        }

        function buildGridOptions() {
            return kendoGridBuilder.buildOptions($scope, {
                id: 'selectedJurisdictions',
                autoBind: true,
                sortable: false,
                actions: viewData.canEdit ? {
                    delete: {
                        onClick: 'vm.topic.validate()'
                    }
                } : null,
                read: function () {
                    return service.getDesignatedJurisdictions(viewData.criteriaId, viewData.eventId).then(function (data) {
                        return data;
                    });
                },
                columns: [{
                    fixed: true,
                    width: '35px',
                    template: '<ip-inheritance-icon ng-if="dataItem.isInherited && !dataItem.isEdited"></ip-inheritance-icon>'
                }, {
                    title: 'workflows.eventcontrol.designatedJurisdictions.selectedJurisdictions',
                    field: 'value',
                    oneTimeBinding: true
                }],
                autoGenerateRowTemplate: true,
                rowAttributes: 'ng-class="{edited: dataItem.isAdded || dataItem.deleted, deleted: dataItem.deleted, \'input-inherited\': dataItem.isInherited&&!dataItem.isEdited}"'
            });
        }

        function selectJurisdictions() {
            picklistService.openModal($scope, {
                displayName: 'picklist.designatedJurisdiction.type',
                multipick: true,
                selectedItems: kendoGridService.activeData(vm.gridOptions),
                keyField: 'key',
                textField: 'value',
                apiUrl: 'api/picklists/designatedjurisdictions?groupId=' + encodeURI(vm.groupKey),
                picklistDisplayName: 'picklist.designatedJurisdiction.type',
                columns: [{
                    title: 'picklist.designatedJurisdiction.description',
                    field: 'value',
                    oneTimeBinding: true
                }],
                templateUrl: 'condor/configuration/rules/workflows/eventcontrol/designated-jurisdictions-picklist-template.html',
                externalScope: {
                    groupName: vm.groupName
                }
            }).then(function (selections) {
                selections = _.sortBy(selections, 'value');
                kendoGridService.sync(vm.gridOptions, selections);
                validate();
            });
        }

        function hasError() {
            return vm.form.$invalid;
        }

        function validate() {
            var hasItems = kendoGridService.hasActiveItems(vm.gridOptions);

            var invalidStatus = hasItems && vm.selectedCountryFlag == null;
            var invalidDesignations = !hasItems && vm.selectedCountryFlag != null;

            if (vm.form.selectedCountryFlag != null) {
                vm.form.selectedCountryFlag.$setValidity('eventcontrol.designatedJurisdiction.missingStage', !invalidStatus);
                vm.form.selectedCountryFlag.$setValidity('eventcontrol.designatedJurisdiction.missingDesignatedJurisdiction', !invalidDesignations);
            }

            return !vm.form.$invalid;
        }

        function isDirty() {
            return vm.form.$dirty || kendoGridService.isGridDirty(vm.gridOptions);
        }

        function getFormData() {
            var delta = service.mapGridDelta(kendoGridService.data(vm.gridOptions), convertToSaveModel);
            return {
                countryFlagForStopReminders: vm.selectedCountryFlag,
                designatedJurisdictionsDelta: delta
            };
        }

        function convertToSaveModel(data) {
            return data.key;
        }
    }
});
