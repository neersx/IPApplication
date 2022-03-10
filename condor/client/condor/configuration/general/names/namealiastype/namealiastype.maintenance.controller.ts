'use strict';
namespace inprotech.configuration.general.names.namealiastype {

    export class NameAliasTypeMaintenanceController {
        static $inject = ['$uibModalInstance', 'options', 'notificationService', 'states', 'NameAliasTypeService', 'hotkeys', 'modalService', '$timeout'];

        public form: ng.IFormController;
        public entity: INameAliasEntity;
        public isEdit: boolean;
        public errors: Array<IValidationError>;

        constructor(private $uibModalInstance, private options: INameAliasModalOptions, private notificationService, private states, private nameAliasTypeService: INameAliasTypeService, private hotkeys, private modalService, private $timeout) {
            this.isEdit = this.options.entity.state === 'updating';
            this.errors = new Array<IValidationError>()
            this.$timeout(this.initShortcuts, 500);
            this.initializeEntity();
        }

        public initializeEntity = (): void => {
            if (this.options.dataItem != null && this.options.dataItem.id !== this.options.entity.id) {
                this.nameAliasTypeService.get(this.options.dataItem.id)
                    .then((entity: INameAliasEntity) => {
                        this.entity = entity;
                        this.entity.state = this.states.updating;
                    });
            } else {
                this.entity = this.options.entity;
                this.clearNameAliasTypeCode();
            }
        }

        clearNameAliasTypeCode = () => {
            if (this.entity.state === this.states.duplicating) {
                this.entity.code = null;
            }
        }

        disable = () => {
            return !(this.form.$dirty && this.form.$valid);
        }

        save = () => {
            this.errors = new Array<IValidationError>();
            if (this.form && this.form.$validate) {
                this.form.$validate();
            }
            if (this.form.$invalid) {
                return;
            }
            if (this.entity.state === this.states.adding || this.entity.state === this.states.duplicating) {
                this.nameAliasTypeService.add(this.entity)
                    .then(this.afterSave, this.afterSaveError);
            } else {
                this.nameAliasTypeService.update(this.entity)
                    .then(this.afterSave, this.afterSaveError);
            }
        }

        afterSave = (response) => {
            if (response.data.result.result === 'success') {
                this.nameAliasTypeService.savedNameAliasTypeIds.push(response.data.result.updatedId);
                if (this.entity.state === this.states.updating) {
                    this.form.$setPristine();
                } else {
                    this.$uibModalInstance.close();
                }
                this.notificationService.success();
                this.options.callbackFn();
            } else {
                this.errors = response.data.result.errors;
                this.notificationService.alert({
                    title: 'modal.unableToComplete',
                    message: this.getError(this.errors[0].field).topic,
                    errors: _.where(response.data.result.errors, {
                        field: null
                    })
                });
            }
        }

        hasUnsavedChanges = (): Boolean => {
            return this.form && this.form.$dirty;
        }

        afterSaveError = (response) => {
            this.errors = response.data.result.errors;
            this.notificationService.alert({
                message: 'modal.alert.unsavedchanges',
                errors: _.where(response.data.result.errors, {
                    field: null
                })
            });
        }

        getError = (field) => {
            return _.find(this.errors, (error: IValidationError) => {
                return error.field === field
            })
        }

        dismissAll = () => {
            if (!this.form.$dirty) {
                this.cancel();
                return;
            }
            this.notificationService.discard()
                .then(() => {
                    this.cancel();
                });
        }

        cancel = () => {
            this.$uibModalInstance.close();
        }

        initShortcuts = () => {
            let saveShortcut: IHotKey = {
                combo: 'alt+shift+s',
                description: 'shortcuts.save',
                callback: () => {
                    if (!this.disable() && this.modalService.canOpen('NameAliasTypeMaintenance')) {
                        this.save();
                    }
                }
            };
            let closeShortcut: IHotKey = {
                combo: 'alt+shift+z',
                description: 'shortcuts.close',
                callback: () => {
                    if (this.modalService.canOpen('NameAliasTypeMaintenance')) {
                        this.dismissAll();
                    }
                }
            };

            this.hotkeys.add(saveShortcut);
            this.hotkeys.add(closeShortcut);
        }
    }

    angular.module('inprotech.configuration.general.names.namealiastype')
        .controller('NameAliasTypeMaintenanceController', NameAliasTypeMaintenanceController);
}