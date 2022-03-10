'use strict';

class SchemasListController {
    static $inject = ['$scope', 'kendoGridBuilder', 'modalService', 'notificationService', 'schemaDataService', '$translate', '$state'];

    public gridOptions: any;
    public hasErrors = false;
    public data: any;

    public selectedSchemaName: string;
    public relatedMappings: string[];

    constructor(private $scope: ng.IScope, private kendoGridBuilder: any, private modalService: any, private notificationService: any, private schemaDataService: ISchemaDataService, private $translate: any, private $state: any) {
        this.gridOptions = this.buildGridOptions();
    }

    public buildGridOptions = (): any => {
        let context = this;

        return this.kendoGridBuilder.buildOptions(this.$scope, {
            id: 'schemas',
            scrollable: false,
            reorderable: false,
            navigatable: true,
            serverFiltering: false,
            autoBind: true,
            read: function () {
                context.data = context.schemaDataService.getSchemas();
                return context.data;
            },
            onDataBound: function () {
                context.hasErrors = _.any(context.gridOptions.data(), { isValid: false });
            },
            columns: this.getColumns()
        });
    }

    public onClickAdd = (): void => {
        let context = this;
        this.openSchemaEditor()
            .then(function () {
                context.refreshData();
            }, function () {
                context.refreshData();
            });
    };

    public onClickEdit = (schema): void => {
        let context = this;
        this.openSchemaEditor({ schemaId: schema.id })
            .then(function () {
                context.refreshData();
            }, function () {
                context.refreshData();
            });
    }

    public onClickDelete = (schema): void => {
        let context = this;

        this.selectedSchemaName = schema.name;
        this.relatedMappings = this.schemaDataService.getMappingNamesFor(schema.id);

        this.notificationService.confirmDelete({
            message: this.$translate.instant('schemaMapping.usLblDeleteMappingConfirm'),
            templateUrl: 'condor/classic/schemaMapping/lists/delete-schema-confirmation.html'
        }, this.$scope).then(function () {
            context.schemaDataService.deleteSchemaPackage(schema.id)
                .then(function () {
                    context.notificationService.success();
                    let index = context.gridOptions.data().indexOf(schema);
                    context.gridOptions.data().splice(index, 1);
                });
        });
    }

    public onClickAddMapping = (schema): void => {
        let context = this;
        this.modalService.openModal({
            id: 'AddMapping',
            controllerAs: 'vm',
            schemaPackage: schema
        }).then(function (response) {
            if (response.result === 'success') {
                context.schemaDataService.getMappings()
                context.notificationService.success();
                context.$state.go('schemamapping.mapping', {
                    id: response.id
                });
            }
        });
    }

    openSchemaEditor = (options = {}): Promise<any> => {
        return this.modalService.openModal
            (_.extend({}, options, {
                id: 'SchemaMappingEditor',
                controllerAs: 'vm'
            }));
    }

    refreshData = (): void => {
        this.gridOptions.$read();
        this.gridOptions.$widget.refresh();
    }

    private getColumns = (): any => {
        return [{
            field: 'error',
            headerTemplate: '<ip-icon-button class="btn-no-bg" id="mappingErrorIcon" button-icon="exclamation-square" type="button" style="cursor:default" ng-class="{\'cpa-icon-exclamation-square-noerror\': !vm.hasErrors}"></ip-icon-button>',
            template: '#if(!isValid) {# <ip-icon-button class="btn-no-bg" button-icon="exclamation-square" type="button" ip-tooltip="{{::\'schemaMapping.schemaErrorTooltip\' | translate }}" data-placement="top"></ip-icon-button> #}#',
            sortable: false,
            width: '30px',
            locked: true
        }, {
            title: 'schemaMapping.usLblPackageName',
            sortable: true,
            field: 'name',
            template: function (dataItem) {
                return '<strong><a data-ng-click="vm.onClickEdit(dataItem)" data-ng-class="pointerCursor" data-ng-bind="dataItem.name"></a></strong>';
            }
        }, {
            title: 'schemaMapping.usLblLastModified',
            field: 'updatedOn',
            sortable: true,
            template: '{{dataItem.updatedOn | localeDate}}'
        },
        {
            sortable: false,
            template: function (dataItem) {
                let html = '<div class="pull-right">';
                html += '<button id="btnAddMapping_{{dataItem.id}}" ng-click="vm.onClickAddMapping(dataItem); $event.stopPropagation();" class="btn btn-prominent schemaMapping-button" translate="schemaMapping.usBtnAdd" ng-disabled="!dataItem.isValid"/>';
                html += '<button id="btnDelete_{{dataItem.id}}" ng-click="vm.onClickDelete(dataItem); $event.stopPropagation();" class="btn btn-discard schemaMapping-button" translate="schemaMapping.usBtnDelete" />';
                html += '</div>'

                return html;
            }
        }];
    }
}

class SchemasList implements ng.IComponentOptions {
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
        this.templateUrl = 'condor/classic/schemaMapping/lists/schemas-list.html';
        this.controller = SchemasListController;
        this.controllerAs = 'vm';
        this.bindings = {};
    }
}

angular.module('Inprotech.SchemaMapping')
    .component('schemasList', new SchemasList());
