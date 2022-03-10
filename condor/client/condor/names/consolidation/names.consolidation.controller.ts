module inprotech.names.consolidation {
    'use strict';
    export class NamesConsolidationController {
        static $inject: string[] = ['$rootScope', '$scope', 'kendoGridBuilder', 'notificationService', 'picklistService', 'kendoGridService', 'NamesConsolidationService', '$translate', 'modalService', 'messageBroker', 'featureDetection', 'scheduler'];
        public gridOptions: any;
        public vm: NamesConsolidationController;
        public targetName;
        public showWebLink: boolean;
        public requestSubmitted: boolean;
        public consolidateJobStatus = '';
        public keepAddressHistory = false;
        public keepTelecomHistory = false;
        private nameConsolidationStatus: any;
        private names: any[];
        private ignoreTypeWarnings = false;
        private ignoreFinancialWarnings = false;
        public isIe = false;
        public inproVersion16 = false;

        constructor($rootScope, public $scope: ng.IScope, public kendoGridBuilder: any, public notificationService, public picklistService, public kendoGridService, private namesConsolidationService: INamesConsolidationService, private $translate, private modalService, public messageBroker, private featureDetection, private scheduler) {
            this.showWebLink = ($rootScope.appContext ? $rootScope.appContext.user ? $rootScope.appContext.user.permissions.canShowLinkforInprotechWeb === true : false : false);
            this.gridOptions = this.buildGridOptions();

            this.$scope.$on('$destroy', () => {
                this.messageBroker.disconnect();
            });

            this.receiveStatusUpdate();
            this.isIe = this.featureDetection.isIe();
            this.inproVersion16 = this.featureDetection.hasRelease16();
        }

        private receiveStatusUpdate = () => {
            let topic = 'name.consolidation.status';

            this.messageBroker.disconnect();
            this.messageBroker.subscribe(topic, (data) => {
                this.scheduler.runOutsideZone(function () {
                    this.$scope.$apply(() => {
                        this.processConsolidationResult(data);
                    });
                });
            });

            this.messageBroker.connect();
        };

        private buildGridOptions = (): any => {
            let options = {
                id: 'names-consolidation-grid',
                autoBind: true,
                pageable: false,
                sortable: true,
                read: () => {
                    return this.names;
                },
                autoGenerateRowTemplate: true,
                rowAttributes: 'ng-class="{edited: dataItem.isWarning, error: dataItem.isError}"',
                columns: this.getColumns(),
                actions: {
                    delete: {
                        onClick: 'vm.onDeleteClick(dataItem)'
                    }
                }
            };

            return this.kendoGridBuilder.buildOptions(this.$scope, options);
        }

        private getColumns = () => {
            return [{
                width: '30px',
                fixed: true,
                template: '<span ng-if="::dataItem.isWarning" class="input-action tooltip-warning text-orange"><span class="cpa-icon cpa-icon-exclamation-triangle" uib-popover="{{::dataItem.validationError}}" popover-class="popover-warning"></span></span>' +
                    '<span ng-if="::dataItem.isError" class="input-action tooltip-error text-red"><span class="cpa-icon cpa-icon-exclamation-triangle" uib-popover="{{::dataItem.validationError}}" popover-class="popover-error"></span></span>'
            }, {
                title: 'namesConsolidation.columns.name',
                field: 'displayName',
                fixed: true,
                menu: false,
                template: '<ip-ie-only-url ng-if="vm.showWebLink" data-url="::vm.getNameLink(dataItem.key)" data-text="::dataItem.displayName"></ip-ie-only-url><span ng-if="!vm.showWebLink">{{::dataItem.displayName}}</span>'
            }, {
                title: 'namesConsolidation.columns.nameCode',
                field: 'code',
                fixed: true,
                menu: false
            }, {
                title: 'namesConsolidation.columns.remarks',
                field: 'remarks',
                fixed: true,
                menu: false
            }, {
                title: 'namesConsolidation.columns.nameNo',
                field: 'key',
                fixed: true,
                width: '200px',
                menu: false
            }, {
                title: 'namesConsolidation.columns.dateCeased',
                fixed: true,
                field: 'ceased',
                width: '200px',
                menu: false,
                template: '<ip-date model="::dataItem.ceased"></ip-date>'
            }, {
                width: '30px',
                fixed: true,
                menu: false,
                template: '<button ng-disabled="vm.requestSubmitted" ng-if="!vm.targetName || vm.targetName.key!==dataItem.key" class="btn-no-bg ng-scope btn btn-icon" ng-click="vm.selectName(dataItem)" button-icon="cpa-icon-merge" uib-tooltip="{{::\'namesConsolidation.selectNameTooltip\' | translate }}"><span class="cpa-icon cpa-icon-merge"></span></button>'
            }];
        }

        public openNamesPicklist = () => {
            this.picklistService.openModal(this.$scope, {
                size: 'xl',
                displayName: 'picklist.name.Name',
                multipick: true,
                selectedItems: this.names,
                label: 'picklist.name.Name',
                keyField: 'key',
                textField: 'code',
                apiUrl: 'api/picklists/names',
                picklistDisplayName: 'picklist.name.Name',
                columns: [{
                    title: 'picklist.name.Name',
                    field: 'displayName'
                }, {
                    title: 'picklist.name.Code',
                    field: 'code'
                }, {
                    title: 'picklist.name.Remarks',
                    field: 'remarks'
                }],
                extendQuery: query => this.includeCeasedName(query)
            })
                .then((selectedNames) => {
                    this.names = selectedNames;
                    this.clearErrorsAndRefreshGrid();
                });
        }

        public includeCeasedName = (query) => {
            return angular.extend({}, query, {
                showCeased: true
            });
        }

        public onDeleteClick = (dataItem) => {
            if (this.requestSubmitted) {
                dataItem.deleted = false;
                return;
            }
            this.names = _.reject(this.names, function (item) {
                return item.key === dataItem.key;
            });
            this.gridOptions.search();
        }

        public selectName = (name) => {
            this.targetName = name;
            this.clearErrorsAndRefreshGrid();
        }

        public showIeRequired = (url) => {
            this.modalService.openModal({
                id: 'ieRequired',
                controllerAs: 'vm',
                url: this.featureDetection.getAbsoluteUrl(url)
            });
        }

        public getNameLink = (nameNo: string): string => {
            return '../default.aspx?nameid=' + encodeURIComponent(nameNo);
        };

        public reset = () => {
            if (this.names && this.names.length > 0 || this.targetName) {
                this.notificationService.discard().then(() => {
                    this.names = [];
                    this.targetName = null;
                    this.ignoreTypeWarnings = false;
                    this.ignoreFinancialWarnings = false;
                    this.consolidateJobStatus = '';
                    this.gridOptions.search();
                });
            }
        }

        private clearErrorsAndRefreshGrid = () => {
            if (this.names && this.names.length > 0) {
                _.each(this.names, (i: any) => {
                    i.isError = false;
                    i.isWarning = false;
                    i.validationError = null;
                });
                this.ignoreTypeWarnings = false;
                this.ignoreFinancialWarnings = false;
                this.gridOptions.search();
            }
        }

        public isRunDisabled = () => {
            return this.requestSubmitted || !(this.targetName && this.hasNoError());
        }

        public runRequest = () => {
            let serviceCall = () => {
                this.namesConsolidationService
                    .consolidate(Number(this.targetName.key), this.ignoreTypeWarnings, this.ignoreFinancialWarnings, this.keepAddressHistory, this.keepTelecomHistory, _.pluck(this.getNamesToConsolidate(), 'key'))
                    .then((resp) => {
                        this.consolidateJobStatus = '';
                        if (resp.status) {
                            this.requestSubmitted = true;
                            this.notificationService.success();
                        } else {
                            this.setValidationErrors(resp.errors);
                            this.gridOptions.search().then(() => {
                                this.showValidationResultPopups(resp.financialCheckPerformed, resp.errors);
                            });
                        }
                    });
            };

            if (this.hasNoWarning() && this.hasNoError()) {
                this.notificationService.confirm({
                    title: 'namesConsolidation.confirmation.title',
                    message: 'namesConsolidation.confirmation.message',
                    cancel: 'button.cancel',
                    continue: 'button.proceed'
                }).then(() => {
                    serviceCall();
                });
            } else {
                serviceCall();
            }
        }

        private hasNoError = () => {
            if (this.getNamesToConsolidate().length > 0) {
                let error = _.find(this.names, (i: any) => {
                    return i.isError;
                });
                return !error;
            }
            return false;
        }

        private hasNoWarning = () => {
            if (this.getNamesToConsolidate().length > 0) {
                let error = _.find(this.names, (i: any) => {
                    return i.isWarning;
                });
                return !error;
            }
            return false;
        }

        private showValidationResultPopups = (financialCheckPerformed: boolean, errors: any[]) => {
            if (_.find(errors, (e) => {
                return e.isBlocking;
            })) {
                this.showErrorPopup(financialCheckPerformed);
            } else {
                this.showWarningPopup(financialCheckPerformed);
            }
        }

        private showErrorPopup = (financialCheckPerformed: boolean) => {
            let message = 'namesConsolidation.validationErrors.blockingNameType';
            if (financialCheckPerformed) {
                message = 'namesConsolidation.validationErrors.blockingFin';
            }
            this.notificationService.alert({
                message: message
            });
        }

        private showWarningPopup = (financialCheckPerformed: boolean) => {
            let message = '.warningPopupNameType';
            if (financialCheckPerformed) {
                message = '.warningPopupFin';
            }

            this.modalService.openModal({
                id: 'NamesConsolidationConfirmation',
                message: message
            }).then(() => {
                this.ignoreTypeWarnings = true;
                if (financialCheckPerformed) {
                    this.ignoreFinancialWarnings = true;
                }
                this.runRequest();
            });
        }

        private setValidationErrors = (errors: any[]) => {
            _.each(this.names, (i: any) => {
                let found = _.find(errors, (e: any) => {
                    return i.key === e.nameNo
                });
                if (found) {
                    if (found.isBlocking) {
                        i.isError = true;
                        i.isWarning = false;
                    } else {
                        i.isWarning = true;
                    }
                    i.validationError = this.$translate.instant('namesConsolidation.validationErrors.' + found.error);
                }
            });
        }

        public processConsolidationResult = (data) => {
            if (this.nameConsolidationStatus !== data) {
                this.nameConsolidationStatus = data;
                let hasError = false;
                if (this.requestSubmitted === true) {
                    if (data.namesCouldNotConsolidate && data.namesCouldNotConsolidate.length > 0) {
                        _.each(data.namesCouldNotConsolidate, (i: any) => {
                            let errorItem = _.find(this.names, (e: any) => {
                                return i === e.key
                            });
                            if (errorItem) {
                                errorItem.isError = true;
                                errorItem.isWarning = false;
                                errorItem.validationError = this.$translate.instant('namesConsolidation.consolidationError');
                                hasError = true;
                            }
                        });
                    }

                    if (data.namesConsolidated && data.namesConsolidated.length > 0) {
                        _.each(data.namesConsolidated, (i: any) => {
                            let successItem = _.find(this.names, (e: any) => {
                                return i === e.key
                            });

                            if (successItem) {
                                this.names = _.reject(this.names, function (item) {
                                    return item.key === i;
                                });
                            }
                        });
                    }

                    this.gridOptions.search();

                    if (data.isCompleted === true) {
                        this.requestSubmitted = false;
                        if (this.consolidateJobStatus === 'other') {
                            this.consolidateJobStatus = ''
                        } else {
                            this.consolidateJobStatus = hasError ? 'error' : 'success';
                        }
                    }
                } else if (data.isCompleted === false) {
                    this.consolidateJobStatus = 'other';
                    this.requestSubmitted = true;
                }
            }
        }

        private getNamesToConsolidate = () => {
            return _.filter(this.names,
                (i) => {
                    return !this.targetName || this.targetName.key !== i.key
                });
        }
    }

    angular.module('inprotech.names.consolidation')
        .controller('NamesConsolidationController', NamesConsolidationController);
}