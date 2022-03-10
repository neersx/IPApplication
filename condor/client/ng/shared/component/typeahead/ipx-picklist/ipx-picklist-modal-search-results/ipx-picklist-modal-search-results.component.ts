import { HttpClient } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, EventEmitter, Input, OnInit, Output, ViewChild } from '@angular/core';
import { SelectableSettings } from '@progress/kendo-angular-grid';
import { LocalSettings } from 'core/local-settings';
import { Observable, of } from 'rxjs';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import * as _ from 'underscore';
import { TypeaheadConfig } from '../../ipx-typeahead/typeahead.config.provider';
import { IpxPicklistMaintenanceService } from '../ipx-picklist-maintenance.service';
import { IpxModalOptions } from '../ipx-picklist-modal-options';
import { NavigationEnum } from '../ipx-picklist-search-field/ipx-picklist-search-field.component';

@Component({
    selector: 'ipx-picklist-modal-search-results',
    templateUrl: 'ipx-picklist-modal-search-results.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxPicklistModalSearchResultsComponent implements OnInit {
    gridOptions: IpxGridOptions;
    isGridOptionsSet = false;
    searchValue: any;
    selectedDataItem: any;
    @Input() typeaheadOptions: TypeaheadConfig;
    @Input() modalOptions: IpxModalOptions;
    @Input() autoApplySelection = true;
    @Input() canNavigate: Boolean;
    @Output() readonly onRowSelect = new EventEmitter();
    @Output() readonly onDataItemClicked = new EventEmitter();
    @Output() readonly pageChanged = new EventEmitter();
    @Output() readonly rowOnMaintnance = new EventEmitter();
    @ViewChild('searchResultGrid') resultGrid: IpxKendoGridComponent;

    constructor(private readonly http: HttpClient, private readonly service: IpxPicklistMaintenanceService,
        private readonly gridNavigationService: GridNavigationService, readonly localSettings: LocalSettings) { }

    ngOnInit(): void {
        // tslint:disable-next-line: strict-boolean-expressions
        this.searchValue = this.modalOptions.searchValue || '';
        if (this.typeaheadOptions.picklistColumns && this.typeaheadOptions.picklistColumns.length > 0) {
            this.isGridOptionsSet = true;
            this.gridOptions = this.buildGridOptions({ columns: this.typeaheadOptions.picklistColumns });
        } else {
            throw new Error('Picklist Columns needs to be defined in configuration');
        }
    }
    private buildGridOptions(res: any): IpxGridOptions {
        const selectable: SelectableSettings = this.modalOptions.multipick ?
            {
                mode: 'multiple',
                checkboxOnly: true,
                enabled: true
            } :
            {
                mode: 'single',
                enabled: true
            };

        const selectedIds = (this.modalOptions.selectedItems && this.modalOptions.selectedItems.length > 0) ?
            this.modalOptions.selectedItems.map((v) => v[this.typeaheadOptions.keyField]) :
            [];

        const gridOptions: IpxGridOptions = {
            autobind: this.typeaheadOptions.autobind || this.searchValue !== '',
            sortable: true,
            dimRowsColumnName: this.typeaheadOptions.picklistDimmedColumnName,
            pageable: { ...this.typeaheadOptions.pageableOptions, pageSizeSetting: this.typeaheadOptions.pageSizeSetting } || true,
            selectable,
            selectedRecords: { rows: { rowKeyField: this.typeaheadOptions.keyField, selectedKeys: selectedIds, selectedRecords: this.modalOptions.selectedItems } },
            persistSelection: true,
            filterable: !!res.columns.find(c => c.filter),
            picklistCanMaintain: this.modalOptions.picklistCanMaintain,
            // rowMaintenance: {
            //     canMaintain: this.modalOptions.canMaintain
            // },
            maintainanceMetaData$: this.modalOptions.picklistCanMaintain ? this.service.maintenanceMetaData$ : null,
            columnPicker: this.modalOptions.columnMenu || false,
            read$: (queryParams) => this.getGridData(queryParams, this.searchValue),
            filterMetaData$: () => this.getColumnFilterData$(res.columns.find(c => c.filter), this.searchValue),
            columns: res.columns,
            columnSelection: !!this.typeaheadOptions.columnSelectionSetting ? { localSetting: this.typeaheadOptions.columnSelectionSetting } : null
        };

        return gridOptions;
    }

    private getGridData(params: any, searchValue: any): any {

        if (!this.typeaheadOptions.autobind && _.isEmpty(searchValue) && !this.typeaheadOptions.allowEmptySearch) {
            return of([]);
        }
        const qParams = params || {
            skip: 0,
            take: 5
        };

        const criteria = {
            search: typeof (searchValue) === 'string' ? searchValue : searchValue.searchText,
            searchFilter: typeof (searchValue) === 'string' ? null : JSON.stringify(searchValue)
        };

        const extendedCriteria = this.modalOptions.extendQuery ? this.modalOptions.extendQuery(criteria) : criteria;

        return this.service.getItems$(this.typeaheadOptions.apiUrl, extendedCriteria, qParams, this.canNavigate);
    }

    search(value: any): void {
        if (!this.typeaheadOptions.autobind && _.isEmpty(this.searchValue) && _.isEmpty(value.value) && !this.typeaheadOptions.allowEmptySearch) {
            return;
        }
        // tslint:disable-next-line: triple-equals
        if ((value.value != this.searchValue) || (value.action == NavigationEnum.filtersChanged) || this.typeaheadOptions.allowEmptySearch) {
            // tslint:disable-next-line: strict-boolean-expressions
            this.searchValue = value.value || '';
            this.gridOptions._search();
        }
    }

    clear(): void {
        this.searchValue = '';
        if (this.gridOptions.selectedRecords) {
            this.gridOptions.selectedRecords = { rows: { rowKeyField: this.typeaheadOptions.keyField, selectedKeys: [] } };
        }
        this.gridOptions._search();
    }

    onPageChanged(data: any): void {
        this.selectedDataItem = null;
        this.pageChanged.emit();
        if (data.take !== data.oldPageSize) {
            this.gridNavigationService.clearLoadedData();
        }
    }

    onRowSelectionChanged(event: any): void {
        this.onRowSelect.emit({ value: event.rowSelection, isSortingEvent: event.isSortingEvent });
    }

    rowOnMaintnanceTriggered(event: any): void {
        this.rowOnMaintnance.emit(event);
    }

    dataItemClicked(event: any): void {
        this.selectedDataItem = event;
        this.onDataItemClicked.emit(event);
    }

    getColumnFilterData$ = (column: GridColumnDefinition, searchText: string): Observable<any> => {
        const query = {
            search: searchText
        };
        const parameters = this.modalOptions.extendQuery ? this.modalOptions.extendQuery(query) : query;

        return this.http.get(this.typeaheadOptions.apiUrl + '/filterdata/' + column.field, { params: parameters });
    };
}