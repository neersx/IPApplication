interface IDataItemPicklistMaintenanceScope extends ng.IScope {
    vm;
}

class DataItemsPicklistController {
    static $inject = ['$scope', 'hotkeys', 'modalService', 'notificationService', '$uibModal', 'states', '$translate'];

    public saveCall: boolean;
    public form: any;

    constructor(private $scope: IDataItemPicklistMaintenanceScope, private hotkeys, modalService,
        private notificationService, private $uibModal,
        private states, private $translate) {
        this.$scope.vm.onBeforeSave = this.onBeforeSave;
        this.$scope.vm.updateListItemFromMaintenance = this.updateListItemFromMaintenance;
        this.form = {};
        this.init();
    }

    initialiseSqlFields = (callback) => {
        if (this.$scope.vm.entry.isSqlStatement) {
            this.$scope.vm.entry.sql.storedProcedure = null;
        } else {
            this.$scope.vm.entry.sql.sqlStatement = null;
        }
        this.$scope.vm.continueSave = true;
        callback(this.$scope.vm);
    }

    onBeforeSave = (entry, callback) => {
        this.saveCall = true;
        if (this.$scope.vm.maintenance.name.$dirty && this.$scope.vm.maintenanceState === this.states.updating) {
            let message = this.$translate.instant('dataItem.maintenance.editConfirmationMessage') + '<br/>' + this.$translate.instant('dataItem.maintenance.proceedConfirmation');
            this.notificationService.confirm({
                message: message,
                cancel: 'Cancel',
                continue: 'Proceed'
            }).then(() => {
                this.initialiseSqlFields(callback)
            })
        } else {
            this.initialiseSqlFields(callback);
        }
    }

    updateListItemFromMaintenance(listItem, maintenanceItem) {
        listItem.key = maintenanceItem.key;
        listItem.code = maintenanceItem.code;
        listItem.value = maintenanceItem.value;
        listItem.confirmDeleteMessage = 'dataItem.confirmDelete';
    }

    init = () => {
        if (this.$scope.vm.maintenanceState === this.states.adding) {
            this.$scope.vm.entry.isSqlStatement = true;
        }
    }

    cancel = () => {
        this.$uibModal.close();
    }

    dismissAll = () => {
        if (!this.$scope.vm.maintenance.$dirty) {
            this.cancel();
            return;
        }

        this.notificationService.discard()
            .then(() => {
                this.cancel();
            });
    }

    disable = () => {
        return !(this.$scope.vm.maintenance.$dirty && this.$scope.vm.maintenance.$valid);
    }

    initShortcuts = () => {
        this.hotkeys.add({
            combo: 'alt+shift+s',
            description: 'shortcuts.save',
            callback: function () {
                if (!this.disable() && this.modalService.canOpen('DataItemMaintenance')) {
                    this.save();
                }
            }
        });
        this.hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.close',
            callback: function () {
                if (this.modalService.canOpen('DataItemMaintenance')) {
                    this.dismissAll();
                }
            }
        });
    }
}

angular.module('inprotech.picklists')
    .controller('DataItemsPicklistController', DataItemsPicklistController);