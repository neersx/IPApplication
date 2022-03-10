'use strict';
namespace inprotech.configuration.general.names.locality {

    export class LocalityMaintenanceController {
        static $inject = ['$uibModalInstance', 'options', 'notificationService', 'states', 'LocalityService', 'hotkeys', 'modalService'];

        public form: ng.IFormController;
        public entity: ILocalityEntity;
        public isEdit: boolean;
        public errors: Array<IValidationError>;

        constructor(private $uibModalInstance, private options: ILocalityModalOptions, private notificationService, private states, private localityService: ILocalityService, private hotkeys, private modalService) {
            this.isEdit = this.options.entity.currentState === 'updating';
            this.errors = new Array<IValidationError>();
            this.initShortcuts();
            this.initializeEntity();
        }

        public initializeEntity = (): void => {
            if (this.options.dataItem != null && this.options.dataItem.id !== this.options.entity.id) {
                this.localityService.get(this.options.dataItem.id)
                    .then((entity: ILocalityEntity) => {
                        this.entity = entity;
                        this.entity.currentState = this.states.updating;
                    });
            } else {
                this.entity = this.options.entity;
                this.clearCode();
            }
        }

        clearCode = () => {
            if (this.entity.currentState === this.states.duplicating) {
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
            if (this.entity.currentState === this.states.adding || this.entity.currentState === this.states.duplicating) {
                this.localityService.add(this.entity)
                    .then(this.afterSave, this.afterSaveError);
            } else {
                this.localityService.update(this.entity)
                    .then(this.afterSave, this.afterSaveError);
            }
        }

        afterSave = (response) => {
            if (response.data.result.result === 'success') {
                this.localityService.savedIds.push(response.data.result.updatedId);
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

        onCountryChanged = () => {
            if (this.entity.country === null) {
                this.entity.state = null;
            }
        }

        onStateChanged = () => {
            if (this.entity.state != null) {
                this.entity.country = {};
                this.entity.country.code = this.entity.state.countryCode;
                this.entity.country.key = this.entity.state.countryCode;
                this.entity.country.value = this.entity.state.countryDescription;
            }
        }

        extendStatePicklist = (query): any => {
            let extended = angular.extend({}, query, {
                country: this.entity.country === undefined || this.entity.country === null ? '' : this.entity.country.code,
                latency: 888
            });
            return extended;
        }

        initShortcuts = () => {
            let saveShortcut: IHotKey = {
                combo: 'alt+shift+s',
                description: 'shortcuts.save',
                callback: () => {
                    if (!this.disable() && this.modalService.canOpen('LocalityMaintenance')) {
                        this.save();
                    }
                }
            };

            let closeShortcut: IHotKey = {
                combo: 'alt+shift+z',
                description: 'shortcuts.close',
                callback: () => {
                    if (this.modalService.canOpen('LocalityMaintenance')) {
                        this.dismissAll();
                    }
                }
            };

            this.hotkeys.add(saveShortcut);
            this.hotkeys.add(closeShortcut);
        }
    }

    angular.module('inprotech.configuration.general.names.locality')
        .controller('LocalityMaintenanceController', LocalityMaintenanceController);
}