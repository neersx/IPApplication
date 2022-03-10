'use strict';
namespace inprotech.accounting.vat {
    export class AccountingVatController implements ng.IController {
        static $inject = [
            '$scope',
            '$location',
            '$window',
            'VatReturnsService',
            'kendoGridBuilder',
            'localSettings',
            'dateService',
            'dateHelper',
            'modalService',
            'store'
        ];
        public vm: AccountingVatController;
        public gridOptions: any;
        public viewData: any;
        public formData: any;
        form: any;
        service: IVatReturnsService;
        searchedEntity: any;
        selectedEntitiesNames: any;

        constructor(
            private $scope: any,
            private $location: any,
            private $window: ng.IWindowService,
            service: inprotech.accounting.vat.IVatReturnsService,
            private kendoGridBuilder: any,
            private localSettings: inprotech.core.LocalSettings,
            private dateService: any,
            private dateHelper,
            private modalService: any,
            private store
        ) {
            this.vm = this;
            this.service = service;
            this.form = {};
            this.gridOptions = this.buildGridOptions();
        }

        $onInit() {
            if (this.vm.viewData.stateId) {
                let stateId = this.vm.viewData.stateId;
                let tempData = this.store.session.get('hmrcState');
                angular.forEach(this.vm.viewData.entityNames, function(entity) {
                    entity.formattedName = entity.displayName + ' (VRN: ' + (entity.taxCode == null ? '-' : entity.taxCode) + ')';
                });
                if (tempData && tempData[stateId]) {
                    tempData[stateId].fromDate = this.dateHelper.convertForDatePicker(
                        tempData[stateId].fromDate
                    );
                    tempData[stateId].toDate = this.dateHelper.convertForDatePicker(
                        tempData[stateId].toDate
                    );
                    if (!tempData[stateId].open && !tempData[stateId].fulfilled) {
                        tempData[stateId].open = true;
                    }
                    this.formData = angular.copy(tempData[stateId]);
                    this.service.initialiseHmrcHeaders(this.vm.viewData.deviceId)
                    .then(x => {
                        this.getSearchResults()
                    });
                }
            } else {
                angular.forEach(this.vm.viewData.entityNames, function(entity) {
                    entity.formattedName = entity.displayName + ' (VRN: ' + (entity.taxCode == null ? '-' : entity.taxCode) + ')';
                });
                this.setDefaultValues(this.vm.viewData);
                this.formData = angular.copy(this.vm.viewData.search);
                this.formData.multipleEntitiesSelected = false;
                this.formData.selectedEntitiesNames = '';
            }
        }

        public buildGridOptions = (): any => {
            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: 'accounting-vat-obligations',
                autoBind: false,
                autoGenerateRowTemplate: true,
                sortable: {
                    allowUnsort: true
                },
                read: () => { return this.authoriseRead() },
                columns: this.getColumns(),
                columnSelection: {
                    localSetting: this.getColumnSelectionLocalSetting()
                }
            });
        };

        authoriseRead = () => {
            return this.service.getObligations(this.searchCriteria(this.formData)).then((data: any) => {
                if (angular.isDefined(data.readyToRedirect) && data.readyToRedirect === 'ok') {
                    this.redirectOnAuth(data);
                } else {
                    return data;
                }
            });
        };

        private getColumns = (): any => {
            return [{
                    width: 20,
                    fixed: true,
                    field: 'icons',
                    sortable: false,
                    template: '<ip-icon-button ng-if="dataItem.status === \'F\'" class="btn-no-bg" button-icon="file" type="button" ip-tooltip="{{::\'accounting.vatObligations.view\' | translate }}" ng-click="vm.viewVatReturn(dataItem.start, dataItem.end, dataItem.periodKey)"></ip-icon-button>' +
                        '<ip-icon-button ng-if="dataItem.status === \'O\'" class="btn-no-bg" button-icon="check-in" type="button" ip-tooltip="{{::\'accounting.vatObligations.submit\' | translate }}" ng-click="vm.vatSubmitter(dataItem.start, dataItem.end, dataItem.periodKey)"></ip-icon-button>'
                },
                {
                    width: 13,
                    fixed: true,
                    field: 'errors',
                    sortable: false,
                    template: '<span ng-if="dataItem.hasLogErrors"><a class="cpa-icon text-red cpa-icon-history tooltip-error" ng-click="vm.openErrorLog(dataItem.start, dataItem.end, dataItem.periodKey)" ip-tooltip="{{::\'accounting.vatObligations.openErrorLog\' | translate }}"></a></span>'
                },
                {
                    title: 'accounting.vatObligations.status',
                    field: 'status',
                    template: '<span>{{ dataItem.status === \'F\' ? \'accounting.vat.fulfilled\' : \'accounting.vat.open\' | translate}}</span>',
                    oneTimeBinding: true
                },
                {
                    title: 'accounting.vatObligations.start',
                    field: 'start',
                    template: '<span>{{ dataItem.start | date:"' + this.dateService.dateFormat + '" }}</span>',
                    oneTimeBinding: true
                },
                {
                    title: 'accounting.vatObligations.end',
                    field: 'end',
                    template: '<span>{{ dataItem.end | date:"' + this.dateService.dateFormat + '" }}</span>',
                    oneTimeBinding: true
                },
                {
                    title: 'accounting.vatObligations.dueDate',
                    field: 'due',
                    template: '<span ng-if="!dataItem.isPastDue || dataItem.status === \'F\'">{{ dataItem.due | date:"' +
                        this.dateService.dateFormat +
                        '" }}</span><span ng-if="dataItem.isPastDue && dataItem.status !== \'F\'" class="text text-red-dark tooltip-error ip-hover-help" ip-tooltip="{{::\'accounting.vatObligations.overdue\' | translate }}">{{ dataItem.due | date:"' +
                        this.dateService.dateFormat +
                        '" }}</span>',
                    oneTimeBinding: true
                },
                {
                    title: 'accounting.vatObligations.submittedDate',
                    field: 'received',
                    template: '<span ng-if="dataItem.received !== null">{{ dataItem.received | date:"' + this.dateService.dateFormat + '" }}</span>',
                    oneTimeBinding: true
                }
            ];
        };

        private getColumnSelectionLocalSetting = () => {
            return this.localSettings.Keys.accounting.vatObligations
                .columnsSelection;
        };

        private setDefaultValues = (viewData: any) => {
            viewData.search = {};
            if (this.vm.viewData.entityNames && this.vm.viewData.entityNames.length === 1) {
                viewData.search.entityName = this.vm.viewData.entityNames[0];
            } else {
                viewData.search.entityName = {
                    taxCode: null
                };
            }
            viewData.search.open = true;
            viewData.search.fulfilled = false;
            viewData.search.fromDate = this.dateHelper.convertForDatePicker(null);
            viewData.search.toDate = this.dateHelper.convertForDatePicker(null);
        };

        clickStatus = (clicked: string) => {
            if (clicked === 'open' && this.formData.fulfilled === false) {
                this.formData.fulfilled = true;
            }
            if (clicked === 'fulfilled' && this.formData.open === false) {
                this.formData.open = true;
            }
        };

        onEntitySelected = () => {
            this.formData.multipleEntitiesSelected = false;
            if (this.formData.entityName.taxCode !== null) {
                let sameTextCodeEntities = _.where(this.vm.viewData.entityNames, { taxCode: this.formData.entityName.taxCode });
                let selectedEntitiesNames = '';
                if (sameTextCodeEntities.length > 1) {
                    this.formData.multipleEntitiesSelected = true;
                    let selectedVRN = this.formData.entityName.taxCode;
                    let counter = 0;
                    angular.forEach(this.vm.viewData.entityNames, function(entity) {
                        if (entity.taxCode === selectedVRN) {
                            counter++;
                            selectedEntitiesNames  += entity.displayName + ((counter < sameTextCodeEntities.length) ? ', ' : '.');
                        }
                    });
                }
                this.formData.selectedEntitiesNames = selectedEntitiesNames;
            }
        };

        search = () => {
            if (this.noEntitySelected()) {
                this.formData.entityName = null;
            }
            this.form.$validate();
            if (this.form.$invalid || this.noEntitySelected() || this.noVatNumber()) {
                return;
            }

            this.service.initialiseHmrcHeaders(this.vm.viewData.deviceId)
                .then(x => {
                    this.getSearchResults();
                });
        };

        getSearchResults = () => {
            this.gridOptions.search();
            this.vm.viewData.hasResults = true;
        }

        redirectOnAuth = (data: any) => {
            let stateKey = data.stateKey;
            this.store.session.set('hmrcState', {
                [stateKey]: this.formData
            });
            this.$window.location.href = data.loginUri;
        }

        clear = () => {
            this.gridOptions.clear();
            this.vm.viewData.hasResults = false;
            this.form.$reset();
            this.form.$setPristine();
            this.formData = angular.copy(this.vm.viewData.search);
            this.formData.entityName = {
                taxCode: null
            };
        };

        vatSubmitter = (fromDate: Date, toDate: Date, periodKey: string) => {
            this.modalService.openModal({
                id: 'VatSubmitterDialog',
                controllerAs: 'vm',
                entityNameNo: this.searchedEntity.id,
                fromDate: fromDate,
                toDate: toDate,
                entityName: this.searchedEntity.displayName,
                entityTaxCode: this.searchedEntity.taxCode,
                periodKey: periodKey,
                selectedEntitiesNames: this.selectedEntitiesNames
            }).then((result: any) => {
                if (result) {
                    this.search();
                }
            });
        };

        viewVatReturn = (fromDate: Date, toDate: Date, periodKey: string) => {
            this.modalService.openModal({
                id: 'ViewVatReturnDialog',
                controllerAs: 'vm',
                entityNameNo: this.searchedEntity.id,
                fromDate: fromDate,
                toDate: toDate,
                entityName: this.searchedEntity.displayName,
                entityTaxCode: this.searchedEntity.taxCode,
                periodKey: periodKey,
                selectedEntitiesNames: this.selectedEntitiesNames
            });
        }

        openErrorLog = (fromDate: Date, toDate: Date, periodKey: string) => {
            this.modalService.openModal({
                id: 'VatErrorLogDialog',
                controllerAs: 'vm',
                entityNameNo: this.searchedEntity.id,
                periodKey: periodKey,
                fromDate: fromDate,
                toDate: toDate,
                entityName: this.searchedEntity.displayName,
                entityTaxCode: this.searchedEntity.taxCode,
                selectedEntitiesNames: this.selectedEntitiesNames
            });
        };

        private searchCriteria = (data: any) => {
            this.searchedEntity = data.entityName;
            this.selectedEntitiesNames = data.selectedEntitiesNames;
            return {
                entityId: data.entityName.id,
                taxNo: data.entityName.taxCode,
                periodFrom: data.fromDate,
                periodTo: data.toDate,
                getOpen: data.open,
                getFulfilled: data.fulfilled
            };
        };

        entityError = () => {
            return this.noVatNumber() ? 'accounting.vat.noVatNumber' : null;
        };

        noEntitySelected = () => {
            return (
                this.formData.entityName &&
                !this.formData.entityName.displayName
            );
        };

        noVatNumber = () => {
            if (!this.formData.entityName) {
                return false;
            }
            if (!this.formData.entityName.displayName) {
                return false;
            } else {
                return (
                    this.formData.entityName.displayName &&
                    !this.formData.entityName.taxCode
                );
            }
        };
    }

    class AccountingVatComponent implements ng.IComponentOptions {
        public controller: any;
        public controllerAs: string;
        public templateUrl: string;
        public bindings: any;
        public viewData: any;
        constructor() {
            this.controller = AccountingVatController;
            this.controllerAs = 'vm';
            this.templateUrl = 'condor/accounting/vat/accounting.vat.html';
            this.bindings = {
                viewData: '<'
            };
        }
    }
    angular
        .module('inprotech.accounting.vat')
        .component('ipVat', new AccountingVatComponent());
}