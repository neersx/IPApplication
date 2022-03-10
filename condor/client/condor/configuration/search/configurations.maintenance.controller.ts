'use strict';
namespace inprotech.configuration.search {
    export class ConfigurationItemMaintenanceController {
        static $inject = ['$uibModalInstance', 'notificationService', 'ConfigurationsService', 'states', 'hotkeys', 'modalService', 'options'];

        public form: ng.IFormController;
        public entity: ConfigurationItemModel;

        constructor(private $uibModalInstance: any, private notificationService: any, private configurationsService: IConfigurationsService, private states: any, private hotkeys: any, private modalService: any, private options: any) {

            if (this.options.dataItem !== this.options.entity) {
                this.entity = angular.copy(this.options.dataItem);
            } else {
                this.entity = angular.copy(this.options.entity);
            }

            this.entity.state = this.states.updating;
            this.initShortcuts();
        }

        isEditState = (): boolean => {
            return this.entity.state === this.states.updating;
        }

        disable = (): boolean => {
            return !(this.form.$dirty && this.form.$valid);
        }

        cancel = (): void => {
            this.$uibModalInstance.close();
        }

        save = () => {
            if (this.form && this.form.$validate) {
                this.form.$validate();
            }
            if (this.form.$invalid) {
                return;
            }
            this.configurationsService.update(this.entity)
                .then(this.afterSave.bind(this), this.afterSaveError.bind(this));
        }

        afterSave = (response) => {
            if (this.entity.state === this.states.updating) {
                let existing = _.find(this.options.allItems, (e: ConfigurationItemModel) => {
                    return e.rowKey === this.entity.rowKey;
                });
                existing.tags = this.entity.tags;
                this.form.$setPristine();
            }
            this.notificationService.success();
            this.options.callbackFn();
        }

        afterSaveError = (response): void => {
            this.notificationService.alert({
                message: 'modal.alert.unsavedchanges'
            });
        }

        hasUnsavedChanges = (): boolean => {
            return this.form.$dirty;
        }

        onNavigate = (): void => {
            this.states.find(this.entity).restore();
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
                    if (!this.disable() && this.modalService.canOpen('ConfigurationItemMaintenance')) {
                        this.save();
                    }
                }
            };

            let closeShortcut: IHotKey = {
                combo: 'alt+shift+z',
                description: 'shortcuts.close',
                callback: () => {
                    if (this.modalService.canOpen('ConfigurationItemMaintenance')) {
                        this.dismissAll();
                    }
                }
            };

            this.hotkeys.add(saveShortcut);
            this.hotkeys.add(closeShortcut);
        }
    }

    angular.module('inprotech.configuration.search')
        .controller('ConfigurationItemMaintenanceController', ConfigurationItemMaintenanceController);
}