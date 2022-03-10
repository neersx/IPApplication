namespace Inprotech.Integration.PtoAccess {

    export class UsptoPrivatePairSponsorshipsController implements ng.IController {
        static $inject = ['$scope', 'modalService', 'kendoGridBuilder', 'notificationService', 'sponsorshipService', 'dateService'];
        public vm = UsptoPrivatePairSponsorshipsController;
        public canScheduleDataDownload = false;
        public envInvalid = false;
        public missingBackgroundProcessLoginId = false;
        clientId: string;
        public gridOptions;
        customerNumbers = '';
        hasSponsorship = false;

        constructor(private $scope, private modalService, private kendoGridBuilder, private notificationService, private sponsorshipService, private dateService) {
            this.gridOptions = this.buildGridOptions();
        }

        onAddOrUpdate = (model) => {
            this.modalService.openModal({
                id: 'NewUsptoSponsorship',
                controllerAs: 'vm',
                data: {
                    item: model,
                    customerNumbers: this.customerNumbers,
                    clientId: this.clientId
                }
            }).then((result) => {
                if (result) {
                    this.gridOptions.search();
                }
            });
        }

        onDelete = (id) => {
            this.notificationService
                .confirmDelete({
                    message: 'modal.confirmDelete.message'
                })
                .then(() => {
                    this.sponsorshipService.delete(id)
                        .then(() => {
                            this.gridOptions.search();
                        });
                });
        }

        onUpdateAccountDetails = () => {
            this.modalService.openModal({
                id: 'updateUsptoAccountDetails',
                controllerAs: 'vm',
                data: {
                    clientId: this.clientId
                }
            });
        }

        setCustomerNumbers = (sponsorShips: any) => {
            this.customerNumbers = '';
            angular.forEach(sponsorShips, s => {
                this.customerNumbers += s.customerNumbers + ', ';
            })
            if (this.customerNumbers !== '') {
                this.customerNumbers = this.customerNumbers.substring(0, this.customerNumbers.length - 2);
            }
        }

        buildGridOptions() {
            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: 'searchResults',
                scrollable: false,
                reorderable: false,
                navigatable: true,
                rowAttributes: 'ng-class="{saved: dataItem.saved}"',
                serverFiltering: false,
                autoBind: true,
                read: () => {
                    return this.sponsorshipService.get()
                        .then((response) => {
                            this.canScheduleDataDownload = response.canScheduleDataDownload;
                            this.envInvalid = response.envInvalid;
                            this.missingBackgroundProcessLoginId = response.missingBackgroundProcessLoginId;
                            this.setCustomerNumbers(response.sponsorships);
                            this.clientId = response.clientId;
                            this.hasSponsorship = response.clientId && response.sponsorships && response.sponsorships.length > 0;
                            return response.sponsorships;
                        });
                },
                columns: [{
                    sortable: false,
                    width: '30px',
                    template: '<ip-icon-button ng-if="dataItem.status===\'error\'" class="btn-no-bg" button-icon="exclamation-circle" type="button" style="cursor:default;color:red" uib-popover="{{:: \'dataDownload.uspto.errors.sponsorship\' | translate: { date: vm.formatDate(dataItem.statusDate) , text: dataItem.errorMessage } }}" popover-placement="auto"></ip-icon-button>'

                }, {
                    title: 'dataDownload.uspto.Columns.name',
                    field: 'name',
                    sortable: true
                }, {
                    title: 'dataDownload.uspto.Columns.sponsoredEmail',
                    field: 'email',
                    sortable: false
                }, {
                    title: 'dataDownload.uspto.Columns.customerNumber',
                    field: 'customerNumbers',
                    sortable: false
                }, {
                    sortable: false,
                    template: function () {
                        let html = '<div class="pull-right">';
                        html += '<button id="btnModify_{{dataItem.id}}" ng-click="vm.onAddOrUpdate(dataItem); $event.stopPropagation();" class="btn btn-prominent schedule-button" translate="dataDownload.uspto.editPassword" />';
                        html += '<button id="btnDelete_{{dataItem.id}}" ng-click="vm.onDelete(dataItem.id); $event.stopPropagation();" class="btn btn-discard schedule-button" translate="dataDownload.uspto.delete" />';
                        html += '</div>';
                        return html;
                    }
                }]
            });
        }

        public formatDate(date) {
            return this.dateService.format(date);
        }
    }

    class UsptoPrivatePairSponsorshipsComponent implements ng.IComponentOptions {
        public controller: any;
        public controllerAs: string;
        public templateUrl: string;
        public bindings: any;
        public viewData: any;
        constructor() {
            this.controller = UsptoPrivatePairSponsorshipsController;
            this.controllerAs = 'vm';
            this.templateUrl = 'condor/classic/integration/ptoaccess/uspto/privatepair/sponsorships.html';
            this.bindings = {
                viewData: '<',
                topic: '<'
            }
        }
    }
    angular.module('Inprotech.Integration.PtoAccess').component('usptoPrivatePairSponsorshipsComponent', new UsptoPrivatePairSponsorshipsComponent());
}