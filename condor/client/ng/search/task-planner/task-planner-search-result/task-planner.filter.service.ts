import { Injectable } from '@angular/core';
import * as _ from 'underscore';

@Injectable()
export class TaskPlannerSerachResultFilterService {
    allSelectedItems: Array<any>;
    getFilter = (isAllPageSelect: boolean, allSelectedItems: Array<any> = [],
        allDeSelectedItems: Array<any> = [], rowKeyField: string, filter: any, searchConfiguration: any): any => {
        let exportFilter: any = {};
        let selectedRowKeys = '';
        if (!isAllPageSelect && allSelectedItems.length > 0) {
            exportFilter = _.clone(filter);
            selectedRowKeys = _.pluck(allSelectedItems, rowKeyField).join(',');
            exportFilter.searchRequest.rowKeys = searchConfiguration.getExportObject(selectedRowKeys).rowKeys;
        } else if (isAllPageSelect && allDeSelectedItems.length > 0) {
            exportFilter = _.clone(filter);
            exportFilter.deselectedIds = [];
            selectedRowKeys = _.pluck(allDeSelectedItems, rowKeyField).join(',');
            exportFilter.deselectedIds = selectedRowKeys.split(',').map(Number);
        } else if (filter) {
            exportFilter = _.clone(filter);
            exportFilter.deselectedIds = [];
        }

        return exportFilter;
    };
}