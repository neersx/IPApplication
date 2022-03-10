'use strict';
namespace inprotech.configuration.general.events.eventnotetypes {
    export class EventNoteTypesMaintenanceController {
        static $inject = ['$uibModalInstance', 'notificationService', 'EventNoteTypesService', 'states', 'hotkeys', 'modalService', 'options'];

        public form: ng.IFormController;
        public entity: EventNoteTypeModel;
        public errors: Array<IValidationError>;

        constructor(private $uibModalInstance: any, private notificationService: any, private eventNoteTypesService: IEventNoteTypesService, private states: any, private hotkeys: any, private modalService: any, private options: any) {
            this.initializeEntity();
            this.initShortcuts();
        }

        initializeEntity = (): void => {
            if (this.options.dataItem != null && this.options.dataItem.id !== this.options.entity.id) {
                this.eventNoteTypesService.get(this.options.dataItem.id)
                    .then((entity: EventNoteTypeModel) => {
                        this.entity = entity;
                        this.entity.state = this.states.updating;
                    });
            } else {
                this.entity = this.options.entity;
            }

        }

        isEditState = (): boolean => {
            return this.entity != null && this.entity.state === this.states.updating;
        }

        disable = (): boolean => {
            return !(this.form.$dirty && this.form.$valid);
        }

        cancel = (): void => {
            this.$uibModalInstance.close();
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
                this.eventNoteTypesService.add(this.entity)
                    .then(this.afterSave.bind(this), this.afterSaveError.bind(this));
            } else {
                this.eventNoteTypesService.update(this.entity)
                    .then(this.afterSave.bind(this), this.afterSaveError.bind(this));
            }
        }

        afterSave = (response) => {
            if (response.data.result.result === 'success') {
                this.eventNoteTypesService.savedEventNoteTypeIds.push(response.data.result.updatedId);
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
                    message: this.getError('description').topic,
                    errors: _.where(response.data.result.errors, {
                        field: null
                    })
                });
            }
        }

        public afterSaveError = (response): void => {
            this.errors = response.data.result.errors;
            this.notificationService.alert({
                message: 'modal.alert.unsavedchanges',
                errors: _.where(response.data.result.errors, {
                    field: null
                })
            });
        }

        getError = (field): any => {
            return _.find(this.errors, (error: any) => {
                return error.field === field
            })
        }

        hasUnsavedChanges = (): boolean => {
            return this.form.$dirty;
        }

        dismissAll = (): void => {
            if (!this.form.$dirty) {
                this.cancel();
                return;
            }

            this.notificationService.discard()
                .then(() => {
                    this.cancel();
                });
        }

        initShortcuts = () => {
            let saveShortcut: IHotKey = {
                combo: 'alt+shift+s',
                description: 'shortcuts.save',
                callback: () => {
                    if (!this.disable() && this.modalService.canOpen('EventNoteTypesMaintenance')) {
                        this.save();
                    }
                }
            };

            let closeShortcut: IHotKey = {
                combo: 'alt+shift+z',
                description: 'shortcuts.close',
                callback: () => {
                    if (this.modalService.canOpen('EventNoteTypesMaintenance')) {
                        this.dismissAll();
                    }
                }
            };

            this.hotkeys.add(saveShortcut);
            this.hotkeys.add(closeShortcut);
        }
    }

    angular.module('inprotech.configuration.general.events.eventnotetypes')
        .controller('EventNoteTypesMaintenanceController', EventNoteTypesMaintenanceController);
}

