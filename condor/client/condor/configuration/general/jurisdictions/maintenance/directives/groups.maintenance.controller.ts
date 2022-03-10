'use strict';
declare var moment: any;
class GroupMembershipMaintenanceController {
    static $inject = ['$scope', '$uibModalInstance', 'options', 'maintenanceModalService', 'notificationService', '$translate', 'utils', 'workflowsEntryControlService', 'dateHelper', 'caseValidCombinationService'];

    public form: ng.IFormController;
    public formData: IGroupFormData;
    public isAddAnother: Boolean;
    public isGroup: Boolean;
    public maintModalService;
    public title: string;
    public isEdit: boolean;
    public isGroupDisabled = true;
    public picklistValidCombination: any;

    constructor(private $scope: ng.IScope, private $uibModalInstance, private options: IGroupModalOptions, private maintenanceModalService, private notificationService, private $translate, private utils, private workflowsEntryControlService, private dateHelper, private caseValidCombinationService) {
        this.isAddAnother = this.options.isAddAnother;
        this.isGroup = this.options.isGroup;
        this.isEdit = this.options.mode === 'edit';
        this.picklistValidCombination = caseValidCombinationService.validCombinationDescriptionsMap;
        this.formData = {};
        if (this.isEdit) {
            let c = new GroupsMaintenanceData(this.options.dataItem, this.dateHelper);
            this.formData = c.FormData;
            if (this.isGroup) {
                this.formData.jurisdiction = {
                    code: this.options.dataItem.id,
                    value: this.options.dataItem.name
                };
            }
        }

        if (angular.isDefined(this.options.dataItem) && this.options.dataItem.isAdded) {
            this.isGroupDisabled = false;
        }
        if (!this.isGroup) {
            this.formData.jurisdiction = {
                code: this.options.parentId,
                value: this.options.jurisdiction
            };
        }
        this.title = this.isEdit ? (this.options.isGroup ? '.editTitleGroup' : '.editTitleMember') : (this.options.isGroup ? '.addTitleGroup' : '.addTitleMember');
        this.maintModalService = this.maintenanceModalService(this.$scope, this.$uibModalInstance, this.options.addItem);
        caseValidCombinationService.initFormData(this.formData);
    }

    apply = (keepOpen: Boolean) => {
        let data: IGroupGridData = new GroupsMaintenanceData(this.formData).GridData;

        this.utils.steps((next) => {
            if (!this.form.$validate()) {
                return false;
            }
            // tslint:disable-next-line:one-line
            else {
                next();
            }
        }, (next) => {
            if (this.workflowsEntryControlService.isDuplicated(_.without(this.options.allItems, this.options.dataItem), data, ['id'])) {
                this.notificationService.alert({
                    message: this.options.type === '0' ? this.$translate.instant('field.errors.groupMembership.duplicateJurisdictionMessage') : (this.isGroup ? this.$translate.instant('field.errors.groupMembership.duplicateGroupMessage') : this.$translate.instant('field.errors.groupMembership.duplicateMemberMessage')),
                    title: this.$translate.instant('modal.unableToComplete')
                });
                return false;
            }
            // tslint:disable-next-line:one-line
            else {
                next();
            }
        }, (next) => {
            if (!this.validateDates(this.formData.dateCeased,
                this.formData.dateCommenced,
                'field.errors.groupMembership.dateJoinedMessage')) {
                return false;
            }
            // tslint:disable-next-line:one-line
            else if (!this.validateDates(this.formData.fullMembershipDate,
                this.formData.dateCommenced,
                'field.errors.groupMembership.dateMembershipMessage')) {
                return false;
            }
            // tslint:disable-next-line:one-line
            else if (!this.validateDates(this.formData.associateMemberDate,
                this.formData.dateCommenced,
                'field.errors.groupMembership.dateAssociateMembershipMessage')) {
                return false;
            }
            // tslint:disable-next-line:one-line
            else if (!this.validateDates(this.formData.dateCeased,
                this.formData.fullMembershipDate,
                'field.errors.groupMembership.dateLeftMessage')) {
                return false;
            }
            // tslint:disable-next-line:one-line
            else if (!this.validateDates(this.formData.dateCeased,
                this.formData.associateMemberDate,
                'field.errors.groupMembership.dateLeftAssociateMessage')) {
                return false;
            }
            // tslint:disable-next-line:one-line
            else {
                next();
            }
            // tslint:disable-next-line:no-shadowed-variable
        }, (next) => {
            this.isEdit ? data.isEdited = true : data.isAdded = true;
            this.maintModalService.applyChanges(data, this.options, this.isEdit, this.isAddAnother, keepOpen);
            return true;
        });
    }

    extendPropertyTypePicklist = (query): any => {
        return this.caseValidCombinationService.extendValidCombinationPickList(query);
    }

    propertyTypeDisabled = (): Boolean => {
        return this.isGroup && (this.formData.group === undefined || this.formData.group.key == null);
    }

    onAssociateMemberChange = (): void => {
        if (this.formData.isAssociateMember) {
            this.formData.fullMembershipDate = null;
        }
    }

    onJurisdictionChange = (): void => {
        if (!this.propertyTypeDisabled()) {
            this.formData.jurisdiction = {
                code: this.formData.group.key,
                value: this.formData.group.value
            };
        }
    }

    isApplyEnabled = (): Boolean => {
        return !this.form.$pristine && !this.form.$invalid;
    }

    hasUnsavedChanges = (): Boolean => {
        return this.form && this.form.$dirty;
    }

    dismiss = (): void => {
        this.$uibModalInstance.dismiss();
    }

    onNavigate = (): boolean => {
        if (this.form.$pristine) {
            return true;
        }
        this.apply(true);
        return true;
    }

    extendJurisdictionPicklist = (query): any => {
        let self = this;
        let extended = angular.extend({}, query, {
            isGroup: this.isGroup,
            excludeCountry: self.options.type === '1' ? self.options.parentId : '',
            latency: 888
        });
        return extended;
    }

    validateDates = (datefirst, datesecond, message): Boolean => {
        let isValid: Boolean = true;
        if (datefirst !== null
            && datesecond !== null) {
            if (datefirst < datesecond) {
                isValid = false;
                this.notificationService.alert({
                    message: this.$translate.instant(message),
                    title: this.$translate.instant('modal.unableToComplete')
                });
            }
        }
        return isValid;
    }
}

angular.module('inprotech.configuration.general.jurisdictions')
    .controller('GroupMembershipMaintenanceController', GroupMembershipMaintenanceController);
