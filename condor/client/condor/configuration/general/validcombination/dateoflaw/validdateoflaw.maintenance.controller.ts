interface IDatesOfLawPicklistMaintenanceScope extends ng.IScope {
    model;
    affectedActions;
    state;
    maintenance;
    canEdit;
    createObj;
    vm;
    $parent
}

class ValidDateOfLawMaintenanceController {

    static $inject = ['$scope', 'kendoGridBuilder', 'dateHelper', 'states', 'jurisdictionMaintenanceService', 'inlineEdit'];

    createObj = this.inlineEdit.defineModel([{
        name: 'retrospectiveAction',
        equals: (objA, objB) => {
            return objA.key === objB.key;
        }
    }, {
        name: 'defaultEventForLaw',
        equals: (objA, objB) => {
            return objA.key === objB.key;
        }
    }, {
        name: 'defaultRetrospectiveEvent',
        equals: (objA, objB) => {
            return objA.key === objB.key;
        }
    }, 'key'
    ]);

    public form: ng.IFormController;

    constructor(private $scope: IDatesOfLawPicklistMaintenanceScope, private kendoGridBuilder, private dateHelper: any, private states: any, private jurisdictionMaintenanceService, private inlineEdit) {
        this.init();
        this.$scope.$parent.vm.onBeforeSave = this.onBeforeSave;
        this.$scope.$parent.vm.hasInlineGridError = this.hasError;
        this.$scope.$parent.vm.isInlineGridDirty = this.isDirty;
        this.$scope.canEdit = true;
        this.$scope.affectedActions = {};
        this.$scope.affectedActions.gridOptions = this.buildGridOptions();
        if (this.$scope.model && this.$scope.model.defaultDateOfLaw) {
            this.$scope.model.defaultDateOfLaw.date = this.$scope.model.defaultDateOfLaw.date ? this.dateHelper.convertForDatePicker(this.$scope.model.defaultDateOfLaw.date) : null;
        }
    }

    onBeforeSave = (entry, callback) => {
        this.Validate();
        if (!this.hasError()) {
            this.$scope.model.affectedActions = this.getDelta();
            this.$scope.vm.saveWithoutValidate();
        }
    }

    getDelta = () => {
        let delta = this.inlineEdit.createDelta(this.$scope.affectedActions.gridOptions.dataSource.data(), this.convertToSaveModel);
        return delta;
    }

    convertToSaveModel = (item) => {
        let defaultDateOfLawEntry = this.$scope.model.defaultDateOfLaw;
        let updatedRecord = {
            key: item.key,
            date: defaultDateOfLawEntry.date,
            jurisdiction: defaultDateOfLawEntry.jurisdiction,
            propertyType: defaultDateOfLawEntry.propertyType,
            defaultEventForLaw: item.defaultEventForLaw,
            defaultRetrospectiveEvent: item.defaultRetrospectiveEvent,
            retrospectiveAction: item.retrospectiveAction
        };

        return updatedRecord;
    }

    onDateBlur = (field, newVal) => {
        if (this.$scope.maintenance['vm.form'].dateOfLaw) {
            this.$scope.maintenance['vm.form'].dateOfLaw.$setValidity('field.errors.notunique', true);
        }
    }

    onAddClick = () => {
        let insertIndex = this.$scope.affectedActions.gridOptions.dataSource.total();
        let newDateOfLawRecord = this.createObj();
        newDateOfLawRecord.defaultEventForLaw = this.$scope.model.defaultDateOfLaw.defaultEventForLaw;
        newDateOfLawRecord.defaultRetrospectiveEvent = this.$scope.model.defaultDateOfLaw.defaultRetrospectiveEvent;
        this.$scope.affectedActions.gridOptions.insertRow(insertIndex, newDateOfLawRecord);
    }


    init = () => {
        if (this.$scope.state === this.states.adding) {
            if (this.$scope.model.validCombinationKeys) {
                this.$scope.model.defaultDateOfLaw = {};
                this.$scope.model.defaultDateOfLaw.jurisdiction =
                    this.$scope.model.validCombinationKeys.jurisdictionModel;
                this.$scope.model.defaultDateOfLaw.propertyType =
                    this.$scope.model.validCombinationKeys.propertyTypeModel;
            }
        }
    }

    Validate = () => {
        let itemsToBeValidated = this.itemsToValidate();
        _.each(itemsToBeValidated, (item: any) => {
            this.checkDuplicateError(item)
        });
    }

    onSelectionChange = (dataItem) => {
        this.checkDuplicateError(dataItem);
    }

    itemsToValidate = () => {
        return _.filter(this.$scope.affectedActions.gridOptions.dataSource.data(), (item: any) => {
            return !item.deleted;
        });
    }

    checkDuplicateError = (dataItem: any) => {
        let itemsToBeValidated = this.itemsToValidate();

        let defaultDateOfLaw = this.createObj();
        defaultDateOfLaw.defaultEventForLaw = this.$scope.model.defaultDateOfLaw.defaultEventForLaw;
        defaultDateOfLaw.defaultRetrospectiveEvent = this.$scope.model.defaultDateOfLaw.defaultRetrospectiveEvent;
        itemsToBeValidated.push(defaultDateOfLaw);
        if (this.isDuplicate(itemsToBeValidated, dataItem) && !dataItem.deleted) {
            dataItem.error('duplicate', true);

        } else {
            dataItem.error('duplicate', false);
        }
        let allItems = _.without(itemsToBeValidated, dataItem);
        _.each(allItems, (r) => {
            if (r.hasError()) {
                if (!this.isDuplicate(allItems, r)) {
                    r.error('duplicate', false);
                }
            }
        });
    }

    hasError = () => {
        return this.inlineEdit.hasError(this.$scope.affectedActions.gridOptions.dataSource.data());
    }

    isDirty = () => {
        return this.inlineEdit.canSave(this.$scope.affectedActions.gridOptions.dataSource.data());
    }

    isDuplicate = (allItems, dataItem) => {
        return this.jurisdictionMaintenanceService.isDuplicated(allItems, dataItem, ['retrospectiveAction', 'defaultEventForLaw']);
    }

    buildGridOptions = (): any => {
        return this.kendoGridBuilder.buildOptions(this.$scope, {
            id: 'affectedActions',
            scrollable: false,
            reorderable: false,
            navigatable: true,
            serverFiltering: false,
            autoBind: true,
            autoGenerateRowTemplate: this.$scope.canEdit,
            actions: {
                delete: {
                    onClick: 'dCtrl.checkDuplicateError(dataItem)'
                }
            },
            read: () => {
                if (this.$scope.model) {
                    return _.map(this.$scope.model.affectedActions, this.createObj);
                }
            },
            rowAttributes: 'ng-form="rowForm" ng-class="{error: rowForm.$invalid || dataItem.hasError(), edited: dataItem.added || dataItem.isDirty(), deleted: dataItem.deleted}"' +
                'uib-tooltip="{{\'picklist.dateoflaw.duplicateEvent\' | translate}}" tooltip-enable="dataItem.error(\'duplicate\')" tooltip-class="tooltip-error" data-tooltip-placement="left"',
            columns: this.getColumns()
        });
    }

    private getColumns = (): any => {
        return [{
            title: 'picklist.dateoflaw.actions',
            fixed: true,
            width: '33%',
            template: this.$scope.canEdit ? '<span ng-if="dataItem.deleted" ng-bind="dataItem.retrospectiveAction.value"></span>' +
                '<ip-typeahead ng-if="!dataItem.deleted" focus-on-add label="" name="retrospectiveAction" ng-model="dataItem.retrospectiveAction" data-config="action" data-key-field="key" data-code-field="code" data-text-field="value" data-picklist-can-maintain="true" ng-change="dCtrl.onSelectionChange(dataItem)"></ip-typeahead>' : '<span ng-bind="dataItem.retrospectiveAction.value"></span>'
        }, {
            title: 'picklist.dateoflaw.determiningEvent',
            fixed: true,
            width: '33%',
            template: this.$scope.canEdit ? '<span ng-if="dataItem.deleted" ng-bind="dataItem.defaultEventForLaw.value"></span>' +
                '<ip-typeahead ng-if="!dataItem.deleted" ip-required data-config="event" label ="" name="determiningEvent" ng-model="dataItem.defaultEventForLaw" data-picklist-can-maintain="true" data-key-field="key" data-code-field="code" data-text-field="value" ng-change="dCtrl.onSelectionChange(dataItem)"></ip-typeahead>' : '<span ng-bind="dataItem.defaultEventForLaw.value"></span>'
        }, {
            title: 'picklist.dateoflaw.retrospectiveEvent',
            fixed: true,
            template: this.$scope.canEdit ? '<span ng-if="dataItem.deleted" ng-bind="dataItem.defaultRetrospectiveEvent.value"></span>' +
                '<ip-typeahead ng-if="!dataItem.deleted" data-config="event" label ="" name="retrospectiveEvent" ng-model="dataItem.defaultRetrospectiveEvent" data-picklist-can-maintain="true" data-key-field="key" data-code-field="code" data-text-field="value"></ip-typeahead>' : '<span ng-bind="dataItem.defaultRetrospectiveEvent.value"></span>'
        }];
    }
}

angular.module('inprotech.picklists')
    .controller('ValidDateOfLawMaintenanceController', ValidDateOfLawMaintenanceController);