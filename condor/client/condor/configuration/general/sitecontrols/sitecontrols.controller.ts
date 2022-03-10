namespace inprotech.configuration.general.sitecontrols {
    export interface ISiteControlsScope extends ng.IScope {
        showCurrentValue;
        service;
    }

    export class SiteControlsController {
        static $inject = ['$scope', '$q', 'viewData', 'SiteControlService', 'kendoGridBuilder', 'notificationService'];

        searchOptions;
        gridOptions;
        canUpdateSiteControls;
        form;
        searchCriteria;

        constructor(private $scope: ISiteControlsScope, private $q: ng.IQService, viewData, private siteControlService: ISiteControlService, private kendoGridBuilder, private notificationService) {
            siteControlService.reset();
            $scope.service = siteControlService;
            $scope.showCurrentValue = (dataItem) => this.showCurrentValue(dataItem);

            this.searchOptions = { releases: viewData.releases };
            this.gridOptions = this.buildGridOptions();
            this.canUpdateSiteControls = viewData.canUpdateSiteControls;

            this.resetGridAndFilter();
        }

        resetOptions() {
            if (!this.siteControlService.isDirty()) {
                this.resetGridAndFilter();
                return;
            }
            this.notificationService.unsavedchanges().then((result) => {
                if (result === 'Save') {
                    this.save().then(() => this.resetGridAndFilter());
                } else {
                    this.siteControlService.discard();
                    this.resetGridAndFilter();
                }
            });
            return;
        }

        resetGridAndFilter() {
            if (this.form) {
                this.form.$reset();
            }
            this.gridOptions.clear();
            this.searchCriteria = {
                isByName: true,
                isByDescription: false,
                isByValue: false,
                text: '',
                release: null,
                components: [],
                tags: []
            };
        }

        buildGridOptions() {
            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: 'searchResults',
                pageable: {
                    pageSize: 20,
                    pageSizes: [5, 10, 20, 50]
                },
                navigatable: true,
                reorderable: false,
                detailTemplate: '<ipt-sitecontrol-detail-view data-parent="dataItem" data-can-update="vm.canUpdateSiteControls"></ipt-sitecontrol-detail-view>',
                autoGenerateRowTemplate: true,
                selectable: 'row',
                rowAttributes: 'ng-class="{saved: $parent.service.find(dataItem.id).isSaved(), edited: $parent.service.find(dataItem.id).isDirty(), error: $parent.service.find(dataItem.id).hasError()}"',
                read: (queryParams) => { return this.siteControlService.search(this.searchCriteria, queryParams); },
                columns: [
                    {
                        title: 'Name',
                        field: 'name',
                        width: '200px',
                        oneTimeBinding: true
                    }, {
                        title: 'Value',
                        template: '{{ $parent.showCurrentValue(dataItem) }}',
                        width: '150px',
                        sortable: false
                    }, {
                        title: 'Description',
                        field: 'description',
                        oneTimeBinding: true
                    }, {
                        title: 'Release',
                        field: 'release',
                        width: '150px',
                        oneTimeBinding: true
                    }, {
                        title: 'Components',
                        field: 'components',
                        width: '200px',
                        sortable: false,
                        oneTimeBinding: true
                    }
                ]
            });
        }

        search() {
            if (this.siteControlService.isDirty()) {
                this.notificationService.unsavedchanges().then((result) => {
                    if (result === 'Save') {
                        this.save().then(() => this.searchCore());
                    } else {
                        this.siteControlService.discard();
                        this.searchCore();
                    }
                });
                return;
            }

            this.searchCore();
        }

        searchCore() {
            this.gridOptions.search().then(() => {
                this.siteControlService.reset();
            });
        }

        save() {
            if (this.siteControlService.hasError()) {
                this.notificationService.alert({
                    message: 'The following Site Controls have Setting Values that do not correspond to the Data Type. Change the Setting Values and save again:',
                    errors: this.siteControlService.getInvalidSiteControls()
                });

                return this.$q.reject();
            } else {
                return this.siteControlService.save().then(() => {
                    this.notificationService.success();
                });
            }
        }

        discard() {
            this.siteControlService.discard();
        }

        onSearchByChange(name) {
            if (!this.searchCriteria.isByName && !this.searchCriteria.isByDescription && !this.searchCriteria.isByValue) {
                this.searchCriteria[name] = true;
            }
        }

        showCurrentValue(row) {
            let detail = this.siteControlService.find(row.id);

            return detail ? detail.value : row.value;
        }

        isSearchDisabled() {
            return this.form.$loading || this.form.$invalid;
        }
    }

    angular.module('inprotech.configuration.general.sitecontrols')
        .controller('SiteControlsController', SiteControlsController);
}
