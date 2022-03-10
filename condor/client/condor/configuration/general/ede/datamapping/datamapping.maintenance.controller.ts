'use strict';
namespace inprotech.configuration.general.ede.datamapping {
    export class DataMappingMaintenanceController {
        static $inject = ['$uibModalInstance', 'options', 'states', 'DataMappingService', 'notificationService', 'modalService', 'hotkeys'];

        public form: ng.IFormController;
        public entity: ITopicEntity;
        public isEdit: boolean;
        public errors: any;
        structure: string;

        constructor(private $uibModalInstance, private options: ITopicModalOptions, private states, private dataMappingService: IDataMappingService, private notificationService, private modalService, private hotkeys) {
            this.isEdit = this.options.entity.state === 'updating';
            this.structure = this.options.structure.slice(0, -1);
            this.entity = options.entity;
            this.errors = [];
            this.initializeEntity();
        }

        public initializeEntity = (): void => {
            if (this.options.dataItem != null && this.options.dataItem.id !== this.options.entity.id) {
                this.dataMappingService.get(this.options.dataSource, this.options.dataItem.id)
                    .then((entity: ITopicEntity) => {
                        this.entity = entity;
                        this.entity.state = this.states.updating;
                    });
            } else {
                this.entity = this.options.entity;
            }
        }

        disable = () => {
            return !(this.form.$dirty && this.form.$valid);
        }

        onChange = () => {
            if (this.entity.ignore) {
                this.entity.event = null;
                return true;
            } else {
                return false;
            }
        }

        save = (): void => {
            let object = {
                mapping: {
                    inputDesc: this.entity.description,
                    id: this.entity.id,
                    output: this.entity.event,
                    notApplicable: this.entity.ignore
                },
                systemId: this.options.dataSource,
                structureId: this.options.structure
            }
            this.errors = [];
            if (this.form && this.form.$validate) {
                this.form.$validate();
            }
            if (this.form.$invalid) {
                return;
            }
            if (this.checkRequiredFields()) {
                if (this.options.entity.state === this.states.adding || this.options.entity.state === this.states.duplicating) {
                    this.dataMappingService.add(object)
                        .then(this.afterSave, this.afterSaveError);
                } else {
                    this.dataMappingService.update(object)
                        .then(this.afterSave, this.afterSaveError);
                }
            } else {
                this.notificationService.alert({
                    title: 'modal.unableToComplete',
                    message: 'dataMapping.maintenance.requiredMessage',
                });
            }
        }

        checkRequiredFields = () => {
            return this.entity.ignore || this.entity.event;
        }

        afterSave = (response) => {
            if (response.data.result.result === 'success') {
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
                    message: response.data.result.errors[0]
                });
            }
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

        getError = () => {
            if (_.any(this.errors)) {
                return 'field.errors.notunique';
            }
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

        cancel = (): void => {
            this.$uibModalInstance.close();
        }

        hasUnsavedChanges = (): Boolean => {
            return this.form && this.form.$dirty;
        }

        initShortcuts = () => {
            let saveShortcut: IHotKey = {
                combo: 'alt+shift+s',
                description: 'shortcuts.save',
                callback: () => {
                    if (!this.disable() && this.modalService.canOpen('DataMappingMaintenance')) {
                        this.save();
                    }
                }
            };

            let closeShortcut: IHotKey = {
                combo: 'alt+shift+z',
                description: 'shortcuts.close',
                callback: () => {
                    if (this.modalService.canOpen('DataMappingMaintenance')) {
                        this.dismissAll();
                    }
                }
            };

            this.hotkeys.add(saveShortcut);
            this.hotkeys.add(closeShortcut);
        }
    }

    angular.module('inprotech.configuration.general.ede.datamapping')
        .controller('DataMappingMaintenanceController', DataMappingMaintenanceController);
}