import { Injectable } from '@angular/core';
import * as _ from 'underscore';
@Injectable()
export class CaseSerachResultFilterService {

    allSelectedItems: Array<any>;
    getFilter = (isAllPageSelect: boolean, allSelectedItems: Array<any> = [],
        allDeSelectedItems: Array<any> = [], rowKeyField: string, filter: any, searchConfiguration: any): any => {
        let exportFilter: any = {};
        let selectedCaseIds = '';
        if (!isAllPageSelect && allSelectedItems.length > 0) {
            exportFilter = (filter instanceof String || typeof filter === 'string') ? { XmlSearchRequest: filter } : _.clone(filter);
            selectedCaseIds = _.pluck(allSelectedItems, rowKeyField).join(',');
            exportFilter.searchRequest = [];
            exportFilter.searchRequest.push(
                searchConfiguration.getExportObject(selectedCaseIds)
            );
        } else if (isAllPageSelect && allDeSelectedItems.length > 0) {
            exportFilter = (filter instanceof String || typeof filter === 'string') ? { XmlSearchRequest: filter } : _.clone(filter);
            exportFilter.deselectedIds = [];
            selectedCaseIds = _.pluck(allDeSelectedItems, rowKeyField).join(',');
            exportFilter.deselectedIds = selectedCaseIds.split(',').map(Number);
            exportFilter.deselectedIds = exportFilter.deselectedIds.filter(this.onlyUniqueCaseId);
        } else if (filter) {
            exportFilter = (filter instanceof String || typeof filter === 'string') ? { XmlSearchRequest: filter } : _.clone(filter);
            exportFilter.deselectedIds = [];
        }

        return exportFilter;
    };

    onlyUniqueCaseId = (value, index, self) => {
        return self.indexOf(value) === index;
    };

    persistSelectedItems = (items: Array<any>): void => {
        this.allSelectedItems = items;
    };

    getPersistedSelectedItems = (): Array<any> => {
        if (!this.allSelectedItems) {
            this.allSelectedItems = [];
        }

        return this.allSelectedItems;
    };
}
