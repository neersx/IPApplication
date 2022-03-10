'use strict';

class ChangeJurisdictionCodeController {
    static $inject = ['$uibModalInstance', 'notificationService', 'jurisdictionMaintenanceService', 'hotkeys', 'modalService', 'options']

    public errors: any;
    public entity: any;
    public changeCodeForm: ng.IFormController;

    constructor(private $uibModalInstance, private notificationService, private jurisdictionMaintenanceService, private hotkeys, private modalService, private options: any) {
        this.errors = {};
        this.initializeEntity();
    }

    initializeEntity = () => {
        this.entity = this.options.entity;
    }

    formValid = () => {
        return (this.changeCodeForm.newJurisdictionCode && this.changeCodeForm.newJurisdictionCode.$dirty && this.changeCodeForm.newJurisdictionCode.$valid)
    }

    cancel = () => {
        this.$uibModalInstance.dismiss('Cancel');
    }

    afterSave = (response) => {
        if (response.data.result === 'success') {
            this.$uibModalInstance.close();
            this.notificationService.success();
        } else {
            this.errors = response.data.errors;
            this.notificationService.alert({
                title: 'modal.unableToComplete',
                message: this.getError('jurisdiction').topic,
                errors: _.where(response.data.errors, {
                    field: null
                })
            });
        }
    }

    afterSaveError = (response) => {
        this.notificationService.alert({
            title: 'modal.unableToComplete',
            message: 'modal.alert.unsavedchanges',
            errors: _.where(response.data.result.errors, {
                field: null
            })
        });
    }

    save = () => {
        this.errors = {};
        if (this.changeCodeForm.$invalid) {
            this.notificationService.alert({
                title: 'modal.unableToComplete',
                message: 'modal.alert.unsavedchanges'
            });
            return;
        }

        this.notificationService.confirm({
            title: 'Confirm Change',
            message: 'jurisdictions.changeCode.confirmation',
            cancel: 'Cancel',
            continue: 'Proceed'
        }).then(() => {
            this.jurisdictionMaintenanceService.changeJurisdictionCode(this.entity)
                .then(this.afterSave, this.afterSaveError);
        });
    }

    getError = (field) => {
        return _.find(this.errors, function (error: any) {
            return error.field === field;
        })
    }

    hasUnsavedChanges = () => {
        return this.changeCodeForm.$dirty;
    }

    dismissAll = () => {
        if (!this.changeCodeForm.$dirty) {
            this.cancel();
            return;
        }

        this.notificationService.discard()
            .then(() => {
                this.cancel();
            });
    }

    initShortcuts = () => {
        this.hotkeys.add({
            combo: 'alt+shift+s',
            description: 'shortcuts.save',
            callback: () => {
                if (this.formValid() && this.modalService.canOpen('ChangeJurisdictionCode')) {
                    this.save();
                }
            }
        });
        this.hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.close',
            callback: () => {
                if (this.modalService.canOpen('ChangeJurisdictionCode')) {
                    this.dismissAll();
                }
            }
        });
    }
}

angular.module('inprotech.configuration.general.jurisdictions')
    .controller('ChangeJurisdictionCodeController', ChangeJurisdictionCodeController);