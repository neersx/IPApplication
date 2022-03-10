namespace inprotech.configuration.search {
    export interface IConfigurationsScope extends ng.IScope {
        service;
    }

    export class ConfigurationsController {
        static $inject = ['$scope', 'viewData', 'ConfigurationsService', 'kendoGridBuilder', 'featureDetection', 'modalService'];

        searchOptions;
        gridOptions;
        form;
        canUpdate;
        searchCriteria;
        private isIe: boolean;
        private inproVersion13: boolean;
        private inproVersion16: boolean;

        constructor(private $scope: IConfigurationsScope, viewData, private configurationsService: IConfigurationsService, private kendoGridBuilder, private featureDetection: inprotech.core.IFeatureDetection, private modalService) {
            this.isIe = featureDetection.isIe();
            this.inproVersion13 = featureDetection.hasRelease13();
            this.inproVersion16 = featureDetection.hasRelease16();
            $scope.service = configurationsService;

            this.searchOptions = {};
            this.canUpdate = viewData.canUpdate;
            this.gridOptions = this.buildGridOptions();
            this.resetGridAndFilter();
        }

        resetOptions() {
            this.resetGridAndFilter();
            return;
        }

        resetGridAndFilter() {
            if (this.form) {
                this.form.$reset();
            }
            this.gridOptions.clear();
            this.searchCriteria = {
                text: '',
                components: [],
                tags: []
            };
        }

        showIeRequired = (url): void => {
            this.modalService.openModal({
                id: 'ieRequired',
                controllerAs: 'vm',
                url: this.featureDetection.getAbsoluteUrl(url)
            });
        }

        showTagList = (item: ConfigurationItemModel): string => {
            return _.pluck(item.tags, 'tagName').join(', ');
        }

        buildLink = (): string => {
            let appsLink = '<a ng-if="!dataItem.legacy" href="{{::dataItem.url}}"><span>{{::dataItem.name}}</span></a>';
            let inproLink = '<a ng-if="dataItem.legacy" href="{{::dataItem.url}}" target="_blank"><span>{{::dataItem.name}}</span></a>';
            if (!this.inproVersion13 && !this.inproVersion16) {
                inproLink = '<span ng-if="dataItem.legacy">{{::dataItem.name}}</span>';
            } else if (!this.isIe) {
                if (this.inproVersion16) {
                    appsLink = '<a ng-if="!dataItem.legacy" href="{{::dataItem.url}}"><span>{{::dataItem.name}}</span></a><a ng-if="dataItem.legacy && !dataItem.ieOnly" target="_blank" href="{{::dataItem.url}}"><span>{{::dataItem.name}}</span></a>';
                    inproLink = '<a ng-if="dataItem.legacy && dataItem.ieOnly" ng-click="vm.showIeRequired(dataItem.url)"><span>{{::dataItem.name}}</span></a>';
                } else {
                    inproLink = '<a ng-if="dataItem.legacy" ng-click="vm.showIeRequired(dataItem.url)"><span>{{::dataItem.name}}</span></a>';
                }
            }
            return appsLink + inproLink;
        }

        checkLegacyLinkCompatibility = (): string => {
            if (!this.inproVersion13 && !this.inproVersion16) {
                return '<ip-icon-button ng-if="dataItem.legacy" id="inproVersionErrorIcon" class="btn-no-bg" button-icon="exclamation-circle" type="button" style="cursor:default;color:red" ip-tooltip="{{::\'configurations.inproMinVersion\' | translate }}" data-placement="top"></ip-icon-button>';
            }

            if (!this.isIe) {
                return this.inproVersion16
                    ? '<ip-icon-button ng-if="dataItem.legacy && dataItem.ieOnly" id="inproVersionErrorIcon" class="btn-no-bg" button-icon="exclamation-circle" type="button" style="cursor:default" ip-tooltip="{{::\'configurations.ieRequired\' | translate }}" data-placement="top"></ip-icon-button>'
                    : '<ip-icon-button ng-if="dataItem.legacy"  id="inproVersionErrorIcon" class="btn-no-bg" button-icon="exclamation-circle" type="button" style="cursor:default" ip-tooltip="{{::\'configurations.ieRequired\' | translate }}" data-placement="top"></ip-icon-button>';
            }
            return '';
        }

        buildGridOptions() {
            let columns: any = [{
                width: '3%',
                template: this.checkLegacyLinkCompatibility(),
                oneTimeBinding: true
            }, {
                title: 'configurations.name',
                width: '20%',
                template: this.buildLink(),
                oneTimeBinding: true
            }, {
                title: 'configurations.description',
                field: 'description',
                width: '30%',
                template: null,
                oneTimeBinding: true
            }, {
                title: 'configurations.components',
                field: 'components',
                width: '20%',
                sortable: false,
                oneTimeBinding: true
            }];

            if (this.canUpdate) {
                columns.push({
                    title: 'configurations.tags',
                    width: '15%',
                    sortable: false,
                    template: '<span>{{vm.showTagList(dataItem)}}</span>',
                    oneTimeBinding: true
                }, {
                    title: 'configurations.actions',
                    width: '20px',
                    sortable: false,
                    template: '<ip-icon-button class="btn-no-bg" button-icon="pencil-square-o" ip-tooltip="{{::\'Edit\' | translate }}" data-ng-click="vm.edit(dataItem); $event.stopPropagation();"></ip-icon-button>',
                    oneTimeBinding: true
                });
            }

            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: 'searchResults',
                pageable: {
                    pageSize: 100,
                    pageSizes: [10, 20, 50, 100]
                },
                autoBind: true,
                navigatable: true,
                reorderable: false,
                sortable: false,
                autoGenerateRowTemplate: true,
                rowAttributes: 'ng-class="{saved: dataItem.saved}"',
                read: (queryParams) => {
                    return this.configurationsService.search(this.searchCriteria, queryParams);
                },
                columns: columns,
            });
        }

        search() {
            this.searchCore();
        }

        searchCore() {
            this.gridOptions.search();
        }

        isSearchDisabled() {
            return this.form.$loading || this.form.$invalid;
        }

        edit = (item): void => {
            this.openConfigurationItemMaintenance(item as ConfigurationItemModel);
        }

        openConfigurationItemMaintenance = (entity: ConfigurationItemModel) => {
            let modalOptions: IConfigurationItemModelOptions = {
                id: 'ConfigurationItemMaintenance',
                entity: entity,
                controllerAs: 'vm',
                dataItem: entity,
                allItems: this.gridOptions.data(),
                callbackFn: this.gridOptions.search
            };
            this.modalService.openModal(modalOptions);
        }
    }

    angular.module('inprotech.configuration.search')
        .controller('ConfigurationsController', ConfigurationsController);
}