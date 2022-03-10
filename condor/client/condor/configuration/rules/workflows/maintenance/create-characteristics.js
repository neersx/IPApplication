angular.module('inprotech.configuration.rules.workflows')
    .controller('CreateCharacteristicsController', function (viewData, modalService, $uibModalInstance, ExtObjFactory,
        workflowsMaintenanceService, workflowsCharacteristicsService, notificationService, $state, $translate, hotkeys, selectedCaseType,
        caseValidCombinationService) {
        'use strict';

        var vm = this;
        var extObjFactory;
        var state;
        var mainService;
        var charsService;
        var canEditProtected;

        extObjFactory = new ExtObjFactory().useDefaults();
        state = extObjFactory.createContext();
        mainService = workflowsMaintenanceService;
        charsService = workflowsCharacteristicsService;

        canEditProtected = viewData.maintainWorkflowRulesProtected;
        vm.canEdit = true;
        vm.hasOffices = viewData.hasOffices;

        vm.form = {};
        vm.formData = {};
        vm.validate = validate;
        vm.fieldClasses = fieldClasses;
        vm.extendPicklistQuery = extendPicklistQuery;
        vm.isDateOfLawDisabled = isDateOfLawDisabled;
        vm.isCaseCategoryDisabled = isCaseCategoryDisabled;

        vm.showExaminationType = charsService.showExaminationType;
        vm.showRenewalType = charsService.showRenewalType;

        vm.picklistValidCombination = caseValidCombinationService.validCombinationDescriptionsMap;
        vm.hasError = hasError;
        vm.getFormData = getTopicFormData;
        vm.isDirty = isDirty;
        vm.discard = discard;
        vm.save = save;
        vm.isSaveEnabled = isSaveEnabled;
        vm.resetNameError = resetNameError;
        vm.initShortcuts = initShortcuts;
        vm.appliesToOptions = mainService.appliesToOptions;
        vm.caseTypeChanged = caseTypeChanged;
        init();

        function init() {
            var data = _.extend({
                criteriaId: null,
                action: null,
                basis: null,
                caseCategory: null,
                caseType: null,
                criteriaName: '',
                dateOfLaw: null,
                inUse: true,
                isEditProtectionBlockedByDescendants: false,
                isEditProtectionBlockedByParent: false,
                isLocalClient: null,
                isProtected: false,
                jurisdiction: null,
                office: null,
                propertyType: null,
                subType: null,
                examinationType: null,
                renewalType: null
            }, viewData.selectedCharacteristics);

            if (viewData.canCreateNegativeWorkflowRules) {
                data.isProtected = true;
            }
            vm.formData = state.attach(data);
            caseValidCombinationService.initFormData(vm.formData);
            vm.formData.$equals = mainService.picklistEquals;

            vm.disableProtectedRadioButtons = isProtectedRadioButtonsDisabled();
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
            return caseValidCombinationService.extendValidCombinationPickList(query);
        }

        function isDateOfLawDisabled() {
            return caseValidCombinationService.isDateOfLawDisabled() || !vm.canEdit;
        }

        function isCaseCategoryDisabled() {
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

        function save() {
            if (!vm.form.$valid) {
                setTouchedForErrorFields(vm.form);
                return;
            }
            var formData = getTopicFormData();
            return mainService.create(formData).then(function (response) {
                if (response.data.status) {
                    afterSave(response.data);
                } else {

                    if (response.data.error.field === 'criteriaName' || response.data.error.field === 'description') {
                        vm.form.criteriaName.$setValidity(response.data.error.message, false);
                    }
                    var translationData = {};
                    if (response.data.error.field === 'characteristicsDuplicate') {
                        translationData = {
                            criteriaId: response.data.error.message
                        }
                    }
                    notificationService.alert({
                        title: 'modal.unableToComplete',
                        message: $translate.instant('workflows.maintenance.errors.' + response.data.error.field, translationData)
                    });
                }
            });
        }

        function afterSave(data) {
            state.save();
            _.extend(vm.formData, data);
            vm.disableProtectedRadioButtons = isProtectedRadioButtonsDisabled();

            $state.go('workflows.details', {
                id: data.criteriaId
            });
        }

        function setTouchedForErrorFields(form) {
            _.each(form.$error, function (errorType) {
                _.each(errorType, function (errorField) {
                    errorField.$setTouched();
                })
            });
        }

        function isSaveEnabled() {
            return vm.form.$dirty && isDirty();
        }

        function resetNameError() {
            vm.form.criteriaName.$setValidity('notunique', null);
        }

        function initShortcuts() {
            hotkeys.add({
                combo: 'alt+shift+s',
                description: 'shortcuts.save',
                callback: function () {
                    if (isSaveEnabled() && modalService.canOpen('CreateCharacteristics')) {
                        vm.save();
                    }
                }
            });
            hotkeys.add({
                combo: 'alt+shift+z',
                description: 'shortcuts.revert',
                callback: function () {
                    if (modalService.canOpen('CreateCharacteristics')) {
                        vm.dismissAll();
                    }
                }
            });
        }

        vm.dismissAll = function () {
            if (!isDirty()) {
                $uibModalInstance.close();
                return;
            }

            notificationService.discard()
                .then(function () {
                    $uibModalInstance.close();
                });
        };
    });