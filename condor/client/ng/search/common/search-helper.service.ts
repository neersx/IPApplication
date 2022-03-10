import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import * as _ from 'underscore';
import { SearchResultColumn } from '../results/search-results.model';
import { SearchOperator } from './search-operators';

export type TypeaheadStringFilter = {
    value?: any;
    operator?: SearchOperator;
};

@Injectable()
export class SearchHelperService {
    onActionComplete$ = new BehaviorSubject(null);

    getKeysFromTypeahead = (valueObj, useKey?: boolean): string => {
        let value: string;
        if (valueObj) {
            if (valueObj instanceof Array) {
                if (valueObj.length > 0) {
                    value = (useKey) ? valueObj.map(j => (!_.isUndefined(j.key)) ? j.key : j.code).join(',')
                        : valueObj.map(j => (j.code) ? j.code : j.key).join(',');
                }
            } else {
                value = (useKey) ? (valueObj.key) ? valueObj.key : valueObj.code
                    : (valueObj.code) ? valueObj.code : valueObj.key;
            }
        }

        return value;
    };

    buildFromToValues = (from, to): any => {
        let returnValue = {};
        if (from && to) {
            returnValue = { ...{ from: (from > to) ? to : from, to: (from > to) ? from : to } };
        } else if (from) {
            returnValue = { ...{ from } };
        } else if (to) {
            returnValue = { ...{ to } };
        }

        return returnValue;
    };

    buildStringFilterFromTypeahead = (valueObj, operator, otherProperties?, useKey?: boolean): TypeaheadStringFilter => {
        const value = this.getKeysFromTypeahead(valueObj, useKey);

        return this.buildStringFilter(value, operator, otherProperties);
    };

    buildStringFilter = (value, operator, otherProperties?): TypeaheadStringFilter => {
        if (this.isFilterApplicable(operator, value)) {
            const filter = { value, operator };
            if (otherProperties) {
                Object.assign(filter, otherProperties);
            }

            return filter;
        }

        return null;
    };

    isFilterApplicable(operator: string, data: any): boolean {
        return operator === SearchOperator.exists || operator === SearchOperator.notExists || (data != null && data !== '');
    }

    computeColumnsWidth(columns: Array<SearchResultColumn>, gridElementWidth: number, isGridCaseSearch = true): void {
        _.each(columns, (col: SearchResultColumn) => {
            switch (col.format) {
                case 'String': {
                    col.width = isGridCaseSearch ? 200 : 150;
                    break;
                }
                case 'Text':
                case 'Formatted Text': {
                    col.width = 300;
                    break;
                }
                default: {
                    col.width = 150;
                    break;
                }
            }
        });

        let totalColumnsWidth = 0;
        _.each(columns, (col: SearchResultColumn) => {
            totalColumnsWidth += col.width;
        });

        if (totalColumnsWidth < gridElementWidth) {
            let textColumns;
            textColumns = _.filter(columns, (col: SearchResultColumn) => {
                return col.format === 'String' || col.format === 'Text' || col.format === 'Formatted Text';
            });

            const columnsToAdjust = textColumns.length > 0 ? textColumns : columns;
            const adjustColumnWidth = (gridElementWidth - totalColumnsWidth) / columnsToAdjust.length;
            _.each(columnsToAdjust, (col: SearchResultColumn) => {
                col.width += adjustColumnWidth;
            });
        }
    }

    getPeriodTypes(): Array<any> {
        return [{
            key: 'D',
            value: 'periodTypes.days'
        }, {
            key: 'W',
            value: 'periodTypes.weeks'
        }, {
            key: 'M',
            value: 'periodTypes.months'
        }, {
            key: 'Y',
            value: 'periodTypes.years'
        }];
    }
}