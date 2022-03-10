'use strict';

class ValidNumbersMaintenanceController {
    static $inject = ['$scope', '$uibModalInstance', 'options', 'maintenanceModalService', 'caseValidCombinationService', 'dateHelper', 'workflowsEntryControlService', 'jurisdictionValidNumbersService', 'notificationService', '$translate', 'modalService'];

    public form: ng.IFormController;
    public formData: IValidNumbersFormData;
    public isAddAnother: Boolean;
    public maintModalService;
    public isEdit: boolean;
    public title: string;
    public picklistValidCombination: any;

    constructor(private $scope: ng.IScope, private $uibModalInstance, private options: any, private maintenanceModalService, private caseValidCombinationService, private dateHelper, private workflowsEntryControlService, private jurisdictionValidNumbersService, private notificationService, private $translate, private modalService) {
        this.isAddAnother = this.options.isAddAnother;
        this.isEdit = this.options.mode === 'edit';
        this.picklistValidCombination = caseValidCombinationService.validCombinationDescriptionsMap;
        this.formData = {};
        if (this.isEdit) {
            let c = new ValidNumbersMaintenanceData(this.options.dataItem, this.dateHelper);
            this.formData = c.FormData;
        }

        this.formData.jurisdiction = {
            code: this.options.parentId,
            value: this.options.jurisdiction
        };

        this.title = this.isEdit ? '.editTitle' : '.addTitle';
        this.maintModalService = this.maintenanceModalService(this.$scope, this.$uibModalInstance, this.options.addItem);
        caseValidCombinationService.initFormData(this.formData);
    }

    dismiss = (): void => {
        this.$uibModalInstance.dismiss();
    }

    extendPicklistQuery = (query): any => {
        return this.caseValidCombinationService.extendValidCombinationPickList(query);
    }

    isCaseCategoryDisabled = (): boolean => {
        return this.caseValidCombinationService.isCaseCategoryDisabled();
    }

    apply = (keepOpen: Boolean) => {
        if (!this.form.$validate()) {
            return false;
        }

        let data: IValidNumbersGridData = new ValidNumbersMaintenanceData(this.formData).GridData;
        if (this.workflowsEntryControlService.isDuplicated(_.without(this.options.allItems, this.options.dataItem), data, ['numberTypeCode', 'propertyTypeCode', 'validFrom'])) {
            this.notificationService.alert({
                message: this.$translate.instant('jurisdictions.maintenance.validNumbers.errors.duplicate'),
                title: this.$translate.instant('modal.unableToComplete')
            });
            return false;
        }

        this.isEdit ? data.isEdited = true : data.isAdded = true;
        this.maintModalService.applyChanges(data, this.options, this.isEdit, this.isAddAnother, keepOpen);
        return true;
    }

    onTestPatternClick = () => {
        this.openTestNumberPattern().then((newData) => {
            this.maintModalService = this.maintenanceModalService(this.$scope, this.$uibModalInstance, this.options.addItem);
            if (newData) {
                if ((this.isEdit && this.formData.pattern !== newData) || !this.isEdit) {
                    this.form.pattern.$setDirty()
                }
                this.formData.pattern = newData;
            }
        });
    }

    openTestNumberPattern = () => {
        return this.modalService.openModal({
            id: 'ValidnumbersTestpattern',
            controllerAs: 'vm',
            bindToController: true,
            pattern: this.formData.pattern ? this.formData.pattern : null
        });
    }

    isApplyEnabled = (): Boolean => {
        return !this.form.$pristine && !this.form.$invalid;
    }

    hasUnsavedChanges = (): Boolean => {
        return this.form && this.form.$dirty;
    }

    onAdditionalValidationChanged = (): void => {
        if (this.formData.additionalValidation) {
            let additionalField = this.form.additionalValidation;
            this.jurisdictionValidNumbersService.validateStoredProcedure(this.formData.additionalValidation.value)
                .then((result) => {
                    additionalField.$setValidity('invalidproc', result);
                });
        }
    }

    onNavigate = (): boolean => {
        if (this.form.$pristine) {
            return true;
        }
        this.apply(true);
        return true;
    }
}

angular.module('inprotech.configuration.general.jurisdictions')
    .controller('ValidNumbersMaintenanceController', ValidNumbersMaintenanceController);
