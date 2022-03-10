angular.module('inprotech.configuration.rules.workflows')
    .controller('OverviewMaintenanceController', function ($scope, $http, $uibModalInstance, workflowsEventControlService, maintenanceModalService, options) {
        'use strict';
        var vm = this;

        _.extend(vm, {
            templateSrc: 'condor/picklists/events/events.html',
            maintenanceState: 'updating',
            criteriaId: options.criteriaId,
            eventId: options.eventId,
            eventDescription: options.eventDescription,

            entry: options.dataItem,
            saveWithoutValidate: saveWithoutValidate,

            title: '.title',
            buttonMode: 'save',
            isEditMode: true,
            isAddAnother: false,
            apply: apply,
            isApplyEnabled: isApplyEnabled,
            dismiss: dismiss,
            hasUnsavedChanges: hasUnsavedChanges
        });

        function apply() {
            if (!vm.maintenance.$validate()) {
                return false;
            }

            if (vm.maintenance.$valid) {
                // onBeforeSave is defined in eventscontroller.
                // it asks wether or not to apply changes to children

                if (vm.onBeforeSave) {
                    vm.onBeforeSave();
                    return;
                }

                return save();
            }

            return false;
        }

        function isApplyEnabled() {
            return workflowsEventControlService.isApplyEnabled(vm.maintenance);
        }
        function hasUnsavedChanges() {
            return vm.maintenance && vm.maintenance.$dirty;
        }

        function dismiss() {
            $uibModalInstance.dismiss();
        }

        function save() {
            var data = _.clone(vm.entry);
            data.isAdded = false;
            data.propagateChanges = vm.entry.propagateChanges;

            return $http.put('api/picklists/events/' + vm.eventId, data)
                .then(function () {
                    $uibModalInstance.close(data);
                });
        }

        function saveWithoutValidate() {
            // saveWithoutValidate function is needed by eventscontroller
            save();
        }
    });