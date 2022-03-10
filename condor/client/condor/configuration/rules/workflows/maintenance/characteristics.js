angular.module('inprotech.configuration.rules.workflows')
    .controller('ipMaintainCharacteristicsController', function (ExtObjFactory, workflowsMaintenanceService, workflowsCharacteristicsService, selectedCaseType, caseValidCombinationService) {
        'use strict';

        var vm = this;
        var extObjFactory;
        var state;
        var mainService;
        var charsService;

        var topicParams;
        var criteriaId;
        var canEditProtected;
        vm.$onInit = onInit;

        function onInit() {
            extObjFactory = new ExtObjFactory().useDefaults();
            state = extObjFactory.createContext();
            mainService = workflowsMaintenanceService;
            charsService = workflowsCharacteristicsService;

            topicParams = vm.topic.params;
            criteriaId = topicParams.criteriaId;
            canEditProtected = topicParams.canEditProtected;

            vm.form = {};
            vm.formData = {};
            vm.validate = validate;
            vm.fieldClasses = fieldClasses;
            vm.extendPicklistQuery = extendPicklistQuery;
            vm.isDateOfLawDisabled = isDateOfLawDisabled;
            vm.isCaseCategoryDisabled = isCaseCategoryDisabled;
            vm.canEdit = topicParams.canEdit;
            vm.hasOffices = topicParams.hasOffices;
            vm.picklistValidCombination = caseValidCombinationService.validCombinationDescriptionsMap;
            vm.resetNameError = resetNameError;
            vm.topic.hasError = hasError;
            vm.topic.getFormData = getTopicFormData;
            vm.topic.isDirty = isDirty;
            vm.topic.discard = discard;
            vm.topic.afterSave = afterSave;
            vm.topic.showPolicingAlertOnSave = showPolicingAlertOnSave;
            vm.topic.validateSaveResponse = validateSaveResponse;
            vm.appliesToOptions = mainService.appliesToOptions;
            vm.caseTypeChanged = caseTypeChanged;
            vm.topic.initializeShortcuts = angular.noop;

            vm.showExaminationType = charsService.showExaminationType;
            vm.showRenewalType = charsService.showRenewalType;

            mainService.getCharacteristics(criteriaId)
            .then(function (data) {
                if (vm.canEdit) {
                    charsService.setValidation(data, vm.form);
                }

                vm.topic.initialised = true;
                vm.formData = state.attach(data);
                caseValidCombinationService.initFormData(vm.formData);
                selectedCaseType.set(vm.formData.caseType);
                vm.formData.$equals = mainService.picklistEquals;
                vm.disableProtectedRadioButtons = isProtectedRadioButtonsDisabled();
            });
        }

        var initCaseValidCombinationService = function () {
            if (!caseValidCombinationService.isFormDataInitialised()) {
                caseValidCombinationService.initFormData(vm.formData);
            }
        }        

        function isProtectedRadioButtonsDisabled() {
            var isDisabled = !vm.canEdit || !canEditProtected;

            if (vm.formData.isEditProtectionBlockedByParent) {
                isDisabled = true;
                vm.protectionDisabledText = 'workflows.maintenance.isUnprotectedWithUnprotectedParent'
            } else if (vm.formData.isEditProtectionBlockedByDescendants) {
                isDisabled = true;
                vm.protectionDisabledText = 'workflows.maintenance.isProtectedWithProtectedChild';
            }

            return isDisabled;
        }

        function caseTypeChanged() {
            selectedCaseType.set(vm.formData.caseType);

            if (!vm.formData.caseType) {
                vm.formData.caseCategory = '';
            }
        }

        function validate() {
            if (!vm.form) {
                return;
            }

            charsService.validate(vm.formData, vm.form);
        }

        function extendPicklistQuery(query) {
            initCaseValidCombinationService();
            return caseValidCombinationService.extendValidCombinationPickList(query);
        }

        function isDateOfLawDisabled() {
            initCaseValidCombinationService();
            return caseValidCombinationService.isDateOfLawDisabled() || !vm.canEdit;
        }

        function isCaseCategoryDisabled() {
            initCaseValidCombinationService();
            return caseValidCombinationService.isCaseCategoryDisabled() || !vm.canEdit;
        }

        function fieldClasses(field) {
            return '{saved: vm.formData.isSaved(\'' + field + '\'), edited: vm.formData.isDirty(\'' + field + '\')}';
        }

        function isDirty() {
            return state.isDirty();
        }

        function discard() {
            vm.form.$reset();
            state.restore();
        }

        function hasError() {
            return vm.form.$invalid && vm.form.$dirty;
        }

        function getFormData() {
            return vm.formData.getRaw();
        }

        function getTopicFormData() {
            var data = getFormData();
            return mainService.createSaveRequestDataForCharacteristics(data);
        }

        function afterSave(data) {
            state.save();
            _.extend(vm.formData, data);
            vm.disableProtectedRadioButtons = isProtectedRadioButtonsDisabled();
        }

        function showPolicingAlertOnSave() {
            if (state.getDirtyItems().length > 0) {
                var dirtyItems = state.getDirtyItems()[0].getDirtyItems();
                var dirtyCount = Object.keys(dirtyItems).length;
                if (dirtyCount === 2 && dirtyItems.criteriaName && dirtyItems.isProtected) {
                    return false;
                }
                if (dirtyCount === 1 && (dirtyItems.criteriaName || dirtyItems.isProtected)) {
                    return false;
                }
            }
            return true;
        }

        function validateSaveResponse(data) {
            if (data.error && !data.status) {
                if (data.error.field === 'criteriaName') {
                    vm.form.criteriaName.$setValidity(data.error.message, false);
                }
                return false;
            }
            return true;
        }

        function resetNameError() {
            vm.form.criteriaName.$setValidity('notunique', null);
        }
    })
    .directive('ipMaintainCharacteristics', function () {
        'use strict';

        return {
            restrict: 'E',
            templateUrl: 'condor/configuration/rules/workflows/maintenance/characteristics.html',
            scope: {},
            controller: 'ipMaintainCharacteristicsController',
            controllerAs: 'vm',
            bindToController: {
                topic: '='
            }
        };
    });