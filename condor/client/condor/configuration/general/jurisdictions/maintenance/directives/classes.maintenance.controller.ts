'use strict';

class ClassesMaintenanceController {
    static $inject = ['$scope', '$uibModalInstance', 'options', 'maintenanceModalService', 'caseValidCombinationService', 'dateHelper', 'workflowsEntryControlService', 'notificationService', '$translate'];

    public form: ng.IFormController;
    public formData: IClassesFormData;
    public isAddAnother: Boolean;
    public isGroup: Boolean;
    public maintModalService;
    public isEdit: boolean;
    public title: string;
    public isClassLabel: boolean;
    public picklistValidCombination: any;

    constructor(private $scope: ng.IScope, private $uibModalInstance, private options: any, private maintenanceModalService, private caseValidCombinationService, private dateHelper, private workflowsEntryControlService, private notificationService, private $translate) {
        this.isAddAnother = this.options.isAddAnother;
        this.isEdit = this.options.mode === 'edit';
        this.picklistValidCombination = caseValidCombinationService.validCombinationDescriptionsMap;
        this.formData = {};
        if (this.isEdit) {
            let c = new ClassesMaintenanceData(this.options.dataItem, this.dateHelper);
            this.formData = c.FormData;
        }

        this.isClassLabel = this.onSubClassChange();

        this.formData.jurisdiction = {
            code: this.options.parentId,
            value: this.options.jurisdiction
        };

        this.title = this.isEdit ? '.editTitle' : '.addTitle';
        this.maintModalService = this.maintenanceModalService(this.$scope, this.$uibModalInstance, this.options.addItem);
        if (this.isAddAnother) {
            this.formData.propertyTypeModel = this.options.propertyTypeModel;
        }
        caseValidCombinationService.initFormData(this.formData);

    }

    dismiss = (): void => {
        this.$uibModalInstance.dismiss();
    }

    extendPropertyTypePicklist = (query): any => {
        return this.caseValidCombinationService.extendValidCombinationPickList(query);
    }

    apply = (keepOpen: Boolean) => {
        if (!this.form.$validate()) {
            return false;
        }

        let data: IClassesGridData = new ClassesMaintenanceData(this.formData).GridData;

        if (this.workflowsEntryControlService.isDuplicated(_.without(this.options.allItems, this.options.dataItem), data, ['class', 'propertyTypeCode', 'subClass'])) {
            this.notificationService.alert({
                message: this.$translate.instant('jurisdictions.maintenance.classes.errors.duplicate'),
                title: this.$translate.instant('modal.unableToComplete')
            });
            return false;
        }

        this.isEdit ? data.isEdited = true : data.isAdded = true;
        this.options.propertyTypeModel = data.propertyTypeModel;
        this.maintModalService.applyChanges(data, this.options, this.isEdit, this.isAddAnother, keepOpen);
        return true;
    }

    isApplyEnabled = (): Boolean => {
        return !this.form.$pristine && !this.form.$invalid;
    }

    extendTMClassPicklist = (query): any => {
        let extended = angular.extend({}, query, {
            propertyTypeCode: this.formData.propertyTypeModel ? this.formData.propertyTypeModel.code : '',
            latency: 888
        });
        return extended;
    }

    onPropertyChanged = () => {
        if (this.formData.propertyTypeModel && !this.formData.propertyTypeModel.allowSubClass) {
            this.formData.subClass = '';
        }
        if (this.formData.propertyTypeModel && this.formData.propertyTypeModel.code !== 'T') {
            this.formData.internationalClasses = [];
        }
        this.onSubClassChange();
    }

    onSubClassChange = () => {
        return this.isClassLabel = this.formData && this.formData.subClass ? false : true;
    }

    hasUnsavedChanges = (): Boolean => {
        return this.form && this.form.$dirty;
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
    .controller('ClassesMaintenanceController', ClassesMaintenanceController);
