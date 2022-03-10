import { Injectable } from '@angular/core';
import * as _ from 'underscore';
@Injectable()

export class IPXKendoGridSelectAllService {
    selectDeSelect: any = {};
    manageSelectDeSelect = (deselectedIds: any, selectedIds: any, allDeSelectIds: any,
        allDeSelectedItems: any, countOfRecord: any, data: any, rowSelectionKey: string, isPagingEnabled: Boolean): any => {
        this.selectDeSelect.deselectedIds = deselectedIds;
        this.selectDeSelect.selectedIds = selectedIds;
        this.selectDeSelect.allDeSelectIds = allDeSelectIds;
        this.selectDeSelect.allDeSelectedItems = allDeSelectedItems;
        this.selectDeSelect.countOfRecord = countOfRecord;
        this.selectDeSelect.nonPagingRecordCount = 0;
        _.each(deselectedIds, (item) => {
            const exists = _.contains(this.selectDeSelect.allDeSelectIds, item.toString());
            if (!exists) {
                this.selectDeSelect.allDeSelectIds.push(item.toString());
                this.setAllDeSelectedItem({ items: data }, item.toString(), rowSelectionKey, this.selectDeSelect.allDeSelectedItems);
                if (isPagingEnabled) {
                    const existForCount = _.contains(this.selectDeSelect.countOfRecord, item.toString());
                    this.selectDeSelect.countOfRecord = !!existForCount ? _.without(this.selectDeSelect.countOfRecord, item.toString()) : _.rest(this.selectDeSelect.countOfRecord);
                } else {
                    this.selectDeSelect.nonPagingRecordCount = data.length - this.selectDeSelect.allDeSelectIds.length;
                }
            }
        });
        _.each(selectedIds, (item) => {
            const exists = _.contains(this.selectDeSelect.allDeSelectIds, item.toString());
            if (exists) {
                this.selectDeSelect.allDeSelectIds = _.without(this.selectDeSelect.allDeSelectIds, item.toString());
                this.selectDeSelect.allDeSelectedItems = _.without(this.selectDeSelect.allDeSelectedItems, _.findWhere(this.selectDeSelect.allDeSelectedItems, { [rowSelectionKey]: item }));
                if (isPagingEnabled) {
                    const existForCount = _.contains(this.selectDeSelect.countOfRecord, item.toString());
                    if (!existForCount) {
                        this.selectDeSelect.countOfRecord.push(item.toString());
                    } else {
                        this.selectDeSelect.countOfRecord.push(_.isEmpty(this.selectDeSelect.countOfRecord) ? 0 : _.max(this.selectDeSelect.countOfRecord) + 1);
                    }
                } else {
                    this.selectDeSelect.nonPagingRecordCount = data.length - this.selectDeSelect.allDeSelectIds.length;
                }
            }
        });

        return this.selectDeSelect;
    };
    setAllDeSelectedItem = (item: any, deselectId: any, rowSelectionKey: string, allDeSelectedItems: any): void => {
        if (item.items) {
            item.items.forEach(items => {
                this.setAllDeSelectedItem(items, deselectId, rowSelectionKey, allDeSelectedItems);
            });
        } else {
            if (item[rowSelectionKey].toString() === deselectId) {
                allDeSelectedItems.push(item);
            }
        }
    };
}