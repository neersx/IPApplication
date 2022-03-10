import { HttpClient } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { KendoGridOptions } from 'ajs-upgraded-providers/directives/kendo.directive.provider';
import * as _ from 'underscore';

@Component({
    selector: 'ngx-dev-policing-grid',
    templateUrl: './policing-example.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class PolicingTestComponent implements OnInit {
    gridOptions: KendoGridOptions;
    constructor(private readonly httpClient: HttpClient, private readonly translate: TranslateService) { }

    ngOnInit(): void {
        this.loadGrid();
    }

    loadGrid = () => {
        const service = this.services();
        const queueType = 'all';
        // tslint:disable-next-line: no-this-assignment
        const vm = this;
        this.gridOptions = {
            context: this,
            id: 'test',
            filterOptions: {
                keepFiltersAfterRead: true,
                sendExplicitValues: true
            },
            pageable: {
                pageSize: 50
            },
            scrollable: false,
            autoBind: true,
            resizable: false,
            reorderable: false,
            navigatable: true,
            selectable: true,
            onSelect: () => {
                vm.gridOptions.clickHyperlinkedCell();
            },
            read: (queryParams) => (
                service.get(queueType, queryParams)
                    .then((data) => this.prepareDataSource(data))
            ),
            readFilterMetadata: (column) => (
                service.getColumnFilterData(column, queueType, this.gridOptions.getCurrentFilters().filters, this.gridOptions.getFiltersExcept(column))
            ),
            hideExpand: true,
            columns: this.getColumns(),
            detailTemplate: '#if(status ===\'in-error\') {# <ip-queue-errorview data-parent="dataItem" style="width:90%"></ip-queue-errorview> #}#',
            // tslint:disable-next-line: no-unbound-method
            onPageSizeChanged: this.onPageSizeChanged,
            // tslint:disable-next-line: no-unbound-method
            onDataCreated: this.onDataCreated,

            // tslint:disable-next-line: only-arrow-functions tslint:disable-next-line: object-literal-shorthand tslint:disable-next-line: space-before-function-paren
            onDataBound: function (): void {
                vm.gridOptions.expandAll('queue');
            }
        };
    };

    onDataCreated(): void {
        // bulkMenuOperations.selectionChange(vm.gridOptions.data());
    }

    onPageSizeChanged(): void {
        // menuSelection.updatePaginationInfo(context, true, vm.gridOptions.pageable.pageSize);
    }

    getColumns(): Array<any> {
        // tslint:disable-next-line: no-this-assignment
        const vm = this;

        return [{
            title: 'policing.queue.status',
            field: 'status',
            sortable: false,
            width: '150px',
            filterable: true,
            template: this.translatedFieldTemplate('status')
        }, {
            title: 'policing.queue.requestDateTime',
            field: 'requested',
            sortable: false,
            width: '200px',
            template: '<ip-date-time model="dataItem.requested"></ip-date-time>',
            filterable: {
                type: 'date'
            }
        }, {
            title: 'policing.queue.user',
            field: 'user',
            sortable: false,
            width: '100px',
            filterable: true
        }, {
            title: 'policing.queue.caseReference',
            field: 'caseReference',
            sortable: false,
            width: '120px',

            // tslint:disable-next-line: only-arrow-functions tslint:disable-next-line: object-literal-shorthand tslint:disable-next-line: space-before-function-paren
            template: function (): string {
                return '<ip-ie-only-url data-url="vm.caseRefUrl(dataItem.caseReference)" ng-class="pointerCursor" data-text="dataItem.caseReference"></ip-ie-only-url>';
            },
            filterable: true
        }, {
            title: 'policing.queue.typeOfRequest',
            field: 'typeOfRequest',
            sortable: false,
            width: '150px',
            filterable: true,
            template: this.translatedFieldTemplate('typeOfRequest')
        }, {
            title: 'policing.queue.event',
            sortable: false,
            width: '250px',
            // tslint:disable-next-line: only-arrow-functions tslint:disable-next-line: object-literal-shorthand tslint:disable-next-line: space-before-function-paren
            template: function (dataItem): string {
                // tslint:disable-next-line: restrict-plus-operands
                return '<a href="#/configuration/rules/workflows/' + encodeURIComponent(dataItem.criteriaId) + '/eventcontrol/' + encodeURIComponent(dataItem.eventId) + '">' + vm.combinedFieldTemplate(dataItem.eventDescription, dataItem.eventId) + '</a>';
            }
        }, {
            title: 'policing.queue.cycle',
            field: 'cycle',
            sortable: false,
            width: '80px'
        }, {
            title: 'policing.queue.actionName',
            field: 'actionName',
            sortable: false,
            width: '100px'
        }, {
            title: 'policing.queue.criteria',
            sortable: false,
            width: '250px',
            // tslint:disable-next-line: only-arrow-functions tslint:disable-next-line: object-literal-shorthand tslint:disable-next-line: space-before-function-paren
            template: function (dataItem): string {
                if (dataItem.criteriaId) {
                    return '<a href="#/configuration/rules/workflows/' + dataItem.criteriaId + '">' + vm.combinedFieldTemplate(dataItem.criteriaDescription, dataItem.criteriaId) + '</a>';
                }

                return '';
            }
        }, {
            title: 'policing.queue.nextRunTime',
            field: 'nextScheduled',
            sortable: false,
            width: '100px',
            template: '<ip-date-time model="dataItem.nextScheduled"></ip-date-time>'
        }, {
            title: 'policing.queue.jurisdiction',
            field: 'jurisdiction',
            sortable: false,
            width: '100px'
        }, {
            title: 'policing.queue.propertyType',
            field: 'propertyName',
            sortable: false,
            width: '100px'
        }, {
            title: 'policing.queue.policingName',
            field: 'policingName',
            sortable: false,
            width: '160px'
        }];
    }

    translatedFieldTemplate(fieldName): string {
        return '<span ng-bind="dataItem.' + fieldName + ' | translate"></span>';
    }

    combinedFieldTemplate(fieldValue, fieldInBrackets): string {
        if (fieldValue && fieldInBrackets) {
            return fieldValue + ' (' + fieldInBrackets + ')';
        }
        if (fieldValue) {
            return fieldValue;
        }
        if (fieldInBrackets) {
            return fieldInBrackets;
        }

        return '';
    }

    services(): any {
        const getRemovedFilters = (newData, currentfilterCodes) => {
            const newDataCodes = _.pluck(newData, 'code');

            return _.difference(currentfilterCodes, newDataCodes);
        };
        const getFilters = (column, oldFilters, newData) => {
            const filterForField: any = _.findWhere(oldFilters, {
                field: column.field
            });

            const filterStringForColumn = filterForField ? filterForField.value : undefined;

            let filtersForColumn = [];
            if (filterStringForColumn) {
                filtersForColumn = filterStringForColumn.split(',');
            }

            if (filtersForColumn.length === 0) {
                return newData;
            }

            const removedFilters = getRemovedFilters(newData, filtersForColumn);

            const filtersToBeAdded: any = _.chain(column.filterable.dataSource.data())
                .filter((d: any) => _.contains(removedFilters, d.code))
                .map((r: any) => ({
                    code: r.code,
                    description: r.description
                }));

            return _.sortBy(_.union(newData, filtersToBeAdded._wrapped), 'description');
        };

        return {
            get: (type, queryParams): Promise<any> => (
                this.httpClient.get('api/policing/queue/all', {
                    params: {
                        params: JSON.stringify(queryParams)
                    }
                })
                    .toPromise()
                    .then((response: any) => response.items)
            ),
            getColumnFilterData: (column, queueType, filtersForColumn, otherFilters): Promise<any> => (
                this.httpClient.get('api/policing/queue/filterData/' + column.field + '/all', {
                    params: {
                        columnFilters: JSON.stringify(otherFilters)
                    }
                })
                    .toPromise()
                    .then((response: Array<any>) => {
                        if (column.field === 'status' || column.field === 'typeOfRequest') {
                            response.forEach(filter => {
                                filter.description = this.translate.instant(filter.code);
                            });

                            return response;
                        }

                        return filtersForColumn ? getFilters(column, filtersForColumn, response) : response;
                    })
            )
        };
    }

    prepareDataSource = (dataSource) => {
        if (dataSource) {
            dataSource.data.forEach((data) => {
                if (!data.id) {
                    data.id = data.requestId;
                }
            }, this);
        }

        return dataSource;
    };

    caseRefUrl = (caseRef): string =>
        '../default.aspx?caseref=' + encodeURIComponent(caseRef);

}