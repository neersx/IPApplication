'use strict';

class ValidNumbersTestPatternController {
    static $inject = ['$scope', '$uibModalInstance', 'options', 'maintenanceModalService', 'notificationService', '$translate'];

    public form: ng.IFormController;
    public formData: IValidNumbersFormData;
    public maintModalService;
    public errorPattern: string;

    constructor(private $scope: ng.IScope, private $uibModalInstance, private options: any, private maintenanceModalService, private notificationService, private $translate) {
        this.errorPattern = '';
        this.formData = {};
        this.formData.pattern = this.options.pattern;
        this.maintModalService = this.maintenanceModalService(this.$scope, this.$uibModalInstance, this.options);
    }

    dismiss = (): void => {
        this.$uibModalInstance.close();
    }

    apply = (keepOpen: Boolean) => {
        this.form.$validate();
        if (this.form.regexPattern.$invalid) {
            return false;
        }
        this.options.pattern = this.formData.pattern;
        this.maintModalService.applyChanges(this.formData.pattern, this.options, false, false, keepOpen);
        return true;
    }

    isApplyEnabled = (): Boolean => {
        return !this.form.$pristine && !this.form.regexPattern.$invalid;
    }

    hasUnsavedChanges = (): Boolean => {
        return this.form && this.form.regexPattern.$dirty;
    }

    onTestPatternClick = () => {
        if (this.formData.pattern) {
            let regEx = new RegExp(this.formData.pattern);
            if (regEx.test(this.formData.testPatternNumber)) {
                this.errorPattern = null;
                this.notificationService.success('jurisdictions.maintenance.validNumbers.testedSuccess');
            } else {
                this.errorPattern = this.$translate.instant('jurisdictions.maintenance.validNumbers.invalidNumber');
            }
        }
    }

    resetErrorPattern = () => {
        this.errorPattern = null;
        this.form.testPatternNumber.$setPristine();
    }

    shouldDisableTestPattern = () => {
        if (this.formData.pattern && this.formData.testPatternNumber) {
            return false;
        } else {
            return true;
        }
    }
}

angular.module('inprotech.configuration.general.jurisdictions')
    .controller('ValidNumbersTestPatternController', ValidNumbersTestPatternController);