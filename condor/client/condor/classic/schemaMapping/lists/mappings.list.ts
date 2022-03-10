'use strict';

class MappingsListController {
    static $inject = ['$scope', 'kendoGridBuilder', 'notificationService', 'schemaDataService'];

    public gridOptions: any;
    public hasErrors = false;
    firstLoad = true;

    constructor(private $scope: ng.IScope, private kendoGridBuilder: any, private notificationService: any, private schemaDataService: ISchemaDataService) {
        this.gridOptions = this.buildGridOptions();

        let context = this;
        this.$scope.$watch(() => { return this.schemaDataService.mappingsModified(); }, (newVal, oldVal) => {
            if (newVal !== oldVal) {
                if (newVal) {
                    context.gridOptions.dataSource.read();
                    context.gridOptions.$widget.refresh();
                    context.schemaDataService.mappingReloaded();
                }
            }
        });
    }

    public buildGridOptions = (): any => {
        let context = this;

        return this.kendoGridBuilder.buildOptions(this.$scope, {
            id: 'mappings',
            scrollable: false,
            reorderable: false,
            navigatable: true,
            serverFiltering: false,
            autoBind: true,
            read: function () {
                return context.schemaDataService.getMappings(context.firstLoad);
            },
            onDataBound: function () {
                context.hasErrors = _.any(context.gridOptions.data(), { isValid: false });
                context.firstLoad = false;
            },
            columns: this.getColumns()
        });
    }

    private getColumns = (): any => {
        return [{
            field: 'isValid',
            headerTemplate: '<ip-icon-button id="mappingErrorIcon" class="btn-no-bg policing-exclamation-square" ng-class="{\'cpa-icon-exclamation-square-noerror\': !vm.hasErrors}" button-icon="exclamation-square" type="button" style="cursor:default"></ip-icon-button>',
            template: '#if(!isValid) {# <ip-icon-button class="btn-no-bg expand-btn error" button-icon="exclamation-square expand-btn" type="button" ip-tooltip="{{::\'schemaMapping.mappingErrorTooltip\' | translate }}" data-placement="top"></ip-icon-button> #}#',
            sortable: false,
            width: '30px',
            locked: true
        }, {
            title: 'schemaMapping.usLblName',
            sortable: true,
            field: 'name',
            template: '#if(isValid) {# <strong><a ui-sref="schemamapping.mapping({id:{{dataItem.id}}})" data-ng-class="pointerCursor">{{dataItem.name}}</a></strong> #} else {#' +
            '<strong><span>{{dataItem.name}}</span></strong> #}#' +
            '<div class="text-muted">' +
            '<div>' + '<span translate="schemaMapping.usLblRoot"></span>: {{dataItem.rootNode.qualifiedName.name}} </div>' +
            '</div>'
        }, {
            title: 'schemaMapping.usLblSchema',
            sortable: true,
            field: 'schemaPackageName',
            template: '<span>{{dataItem.schemaPackageName}}</span>' +
            '<div class="text-muted">' +
            '<div>{{::"schemaMapping.usLblFile" | translate }}: {{dataItem.rootNode.fileName}}</div>' +
            '</div>'
        }, {
            title: 'schemaMapping.usLblLastModified',
            field: 'lastModified',
            sortable: true,
            template: '{{dataItem.lastModified | localeDate}}'
        }, {
            sortable: false,
            template: function (dataItem) {
                let html = '<div class="pull-right">';
                html += '<button id="btnDelete_{{dataItem.id}}" ng-click="vm.onDelete(dataItem); $event.stopPropagation();" class="btn btn-discard schemaMapping-button" translate="schemaMapping.usBtnDelete" />';
                html += '</div>'

                return html;
            }
        }];
    }

    onDelete = (item): any => {
        let context = this;

        this.notificationService.confirmDelete({ message: 'modal.confirmDelete.message' }).then(function () {
            context.schemaDataService.deleteMapping(item.id).then(function () {
                context.notificationService.success();
            });
        });
    }
}

class MappingsList implements ng.IComponentOptions {
    public bindings: any;
    public controller: any;
    public templateUrl: string;
    public restrict: string;
    public transclude: boolean;
    public replace: boolean;
    public controllerAs: string;

    constructor() {
        this.transclude = true;
        this.replace = true;
        this.restrict = 'EA';
        this.templateUrl = 'condor/classic/schemaMapping/lists/mappings-list.html';
        this.controller = MappingsListController;
        this.controllerAs = 'vm';
        this.bindings = {};
    }
}

angular.module('Inprotech.SchemaMapping')
    .component('mappingsList', new MappingsList());
