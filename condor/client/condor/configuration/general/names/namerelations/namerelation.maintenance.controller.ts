'use strict';
namespace inprotech.configuration.general.names.namerelations {

    export class NameRelationMaintenanceController {
        static $inject = ['$uibModalInstance', 'options', 'notificationService', 'states', 'NameRelationService', 'hotkeys', 'modalService'];

        public form: ng.IFormController;
        public entity: any;
        public isEdit: boolean;
        public errors: Array<IValidationError>;
        public ethicalWallOptions: any[];
        constructor(private $uibModalInstance, private options, private notificationService, private states, private nameRelationService: INameRelationService, private hotkeys, private modalService) {
            this.isEdit = this.options.entity.currentState === 'updating';
            this.ethicalWallOptions = [];
            this.errors = new Array<IValidationError>();
            this.initializeForm();
            this.initShortcuts();
            this.initializeEntity();
        }

        initializeForm = (): void => {
            this.nameRelationService.viewData()
                .then((viewData) => {
                    this.ethicalWallOptions = viewData.data.ethicalWallOptions;
                });
        }

        public initializeEntity = (): void => {
            if (this.options.dataItem != null && this.options.dataItem.id !== this.options.entity.id) {
                this.nameRelationService.get(this.options.dataItem.id)
                    .then((entity) => {
                        this.entity = entity;
                        this.entity.currentState = this.states.updating;
                    });
            } else {
                this.entity = this.options.entity;
                if (this.options.entity.currentState === this.states.adding) {
                    this.entity.ethicalWall = '0';
                }
                this.clearCode();
            }
        }

        clearCode = () => {
            if (this.entity.currentState === this.states.duplicating) {
                this.entity.relationshipCode = null;
            }
        }

        disable = () => {
            return !(this.form.$dirty && this.form.$valid) ||
                (!this.entity.isEmployee && !this.entity.isIndividual
                    && !this.entity.isOrganisation);
        }

        save = () => {
            this.errors = new Array<IValidationError>();

            if (this.form && this.form.$validate) {
                this.form.$validate();
            }
            if (this.form.$invalid) {
                return;
            }
            if (this.entity.currentState === this.states.adding || this.entity.currentState === this.states.duplicating) {
                this.nameRelationService.add(this.entity)
                    .then(this.afterSave, this.afterSaveError);
            } else {
                this.nameRelationService.update(this.entity)
                    .then(this.afterSave, this.afterSaveError);
            }
        }

        afterSave = (response) => {
            if (response.data.result.result === 'success') {
                this.nameRelationService.savedIds.push(response.data.result.updatedId);
                if (this.entity.currentState === this.states.updating) {
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
                return error.field === field;
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
            this.hotkeys.add({
                combo: 'alt+shift+s',
                description: 'shortcuts.save',
                callback: () => {
                    if (!this.disable() && this.modalService.canOpen('NameRelationMaintenance')) {
                        this.save();
                    }
                }
            });
            this.hotkeys.add({
                combo: 'alt+shift+z',
                description: 'shortcuts.close',
                callback: () => {
                    if (this.modalService.canOpen('NameRelationMaintenance')) {
                        this.dismissAll();
                    }
                }
            });
        }
    }

    angular.module('inprotech.configuration.general.names.namerelations')
        .controller('NameRelationMaintenanceController', NameRelationMaintenanceController);
}