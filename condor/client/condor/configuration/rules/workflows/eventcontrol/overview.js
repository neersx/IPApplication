angular.module('inprotech.configuration.rules.workflows')
    .component('ipWorkflowsEventControlOverview', {
        templateUrl: 'condor/configuration/rules/workflows/eventcontrol/overview.html',
        bindings: {
            topic: '='
        },
        controllerAs: 'vm',
        controller: function (ExtObjFactory, modalService, $http) {
            'use strict';
            var vm = this;
            var viewData;
            var overview;
            var extObjFactory;
            var state;

            vm.$onInit = onInit;

            function onInit() {
                viewData = vm.topic.params.viewData;
                overview = viewData.overview;
                extObjFactory = new ExtObjFactory().useDefaults();
                state = extObjFactory.createContext();
                vm.parentData = (viewData.isInherited === true && viewData.parent) ? viewData.parent.overview.data : {};
                vm.parentData.unlimitedCycles = (viewData.isInherited === true && viewData.parent) ? (vm.parentData.maxCycles === 9999) : null;

                vm.baseDescription = overview.baseDescription;
                vm.importanceLevelOptions = overview.importanceLevelOptions;
                vm.unlimitedCyclesChecked = unlimitedCyclesChecked;
                vm.maxCyclesChanged = maxCyclesChanged;
                vm.isMaxCyclesDisabled = isMaxCyclesDisabled;
                vm.onEditBaseEvent = onEditBaseEvent;
                vm.ensureDescriptionIsNotEmpty = ensureDescriptionIsNotEmpty;
                vm.formData = state.attach(viewData.overview.data);

                vm.eventId = viewData.eventId;
                vm.canEdit = viewData.canEdit;
                vm.unlimitedCycles = vm.formData.maxCycles === 9999;

                vm.topic.hasError = hasError;
                vm.topic.isDirty = isDirty;
                vm.topic.discard = discard;
                vm.topic.getFormData = getFormData;
                vm.topic.afterSave = afterSave;
                vm.topic.isRespChanged = isRespChanged;
                vm.topic.initializeShortcuts = angular.noop;

                vm.onRespTypeChange = onRespTypeChange;
            }

            function isRespChanged() {
                if (vm.formData.isDirty('name') || vm.formData.isDirty('nameType')) {
                    return true;
                }
                return false;
            }

            function hasError() {
                return !maxCyclesCustomValidate() || vm.form.$invalid && vm.form.$dirty;
            }

            function isDirty() {
                return state.isDirty();
            }

            function unlimitedCyclesChecked() {
                if (vm.unlimitedCycles) {
                    vm.formData.maxCycles = 9999;
                }
            }

            function maxCyclesChanged() {
                if (vm.formData.maxCycles >= 9999) {
                    vm.formData.maxCycles = 9999;
                    vm.unlimitedCycles = true;
                }
            }

            function isMaxCyclesDisabled() {
                return !vm.canEdit || vm.unlimitedCycles;
            }

            function discard() {
                vm.form.$reset();
                state.restore();
            }

            function getFormData() {
                var formData = _.clone(vm.formData.getRaw());

                if (formData.name) {
                    formData.dueDateRespNameId = formData.name.key;
                }

                if (formData.nameType) {
                    formData.dueDateRespNameTypeCode = formData.nameType.code;
                }

                return formData;
            }

            function afterSave() {
                state.save();
            }

            function onRespTypeChange() {
                vm.formData.name = null;
                vm.formData.nameType = null;
            }

            function maxCyclesCustomValidate() {
                var valid = true;

                if (vm.form.maxCycles) {
                    valid = viewData.unlimitedCycles || (viewData.dueDateCalcMaxCycles <= vm.formData.maxCycles);
                    vm.form.maxCycles.$setValidity('eventcontrol.overview.maxCycles', valid);
                }

                return valid;
            }

            function onEditBaseEvent() {
                $http.get('api/picklists/events/' + viewData.eventId)
                    .then(function (response) {
                        modalService.openModal({
                            id: 'OverviewMaintenance',
                            mode: 'edit',
                            dataItem: response.data.data,
                            allItems: null,
                            criteriaId: viewData.criteriaId,
                            eventId: viewData.eventId,
                            eventDescription: viewData.overview.data.description,
                            isAddAnother: false,
                            addItem: null
                        }).then(function (edited) {
                            vm.baseDescription = edited.description;

                            if (!edited.propagateChanges) return;

                            if (_.some(edited.updatedFields, { id: 'description', updated: true })) {
                                vm.formData.description = edited.description;
                                vm.formData.setDirty('description', false);
                            }

                            if (_.some(edited.updatedFields, { id: 'maxCycles', updated: true })) {
                                vm.formData.maxCycles = edited.maxCycles;

                                if (vm.unlimitedCycles != edited.unlimitedCycles) {
                                    vm.unlimitedCycles = edited.unlimitedCycles;
                                    vm.formData.setDirty('unlimitedCycles', false);
                                    vm.unlimitedCyclesChecked();
                                }

                                vm.formData.setDirty('maxCycles', false);
                            }

                            if (_.some(edited.updatedFields, { id: 'internalImportance', updated: true })) {
                                vm.formData.importanceLevel = edited.internalImportance;
                                vm.formData.setDirty('importanceLevel', false);
                            }

                            if (_.some(edited.updatedFields, { id: 'allowDateRecalc', updated: true })) {
                                vm.topic.params.viewData.dueDateCalcSettings.recalcEventDate = edited.recalcEventDate;
                            }

                            if (_.some(edited.updatedFields, { id: 'suppressDueDateCalc', updated: true })) {
                                vm.topic.params.viewData.dueDateCalcSettings.doNotCalculateDueDate = edited.suppressCalculation;
                            }
                        });
                    });
            }

            function ensureDescriptionIsNotEmpty() {
                if (!vm.formData.description) {
                    vm.formData.description = vm.baseDescription;
                }
            }
        }
    });