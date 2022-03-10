import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import * as _ from 'underscore';
@Injectable()

export class IpxGroupingService {
    groupedDataSet$ = new BehaviorSubject<Array<any>>([]);
    isProcessCompleted$ = new BehaviorSubject<boolean>(false);

    convertRecordForGrouping = (record: any): any => {
        let result = null;
        if (record.aggregates) {
            const groupModel = {
                detail: record.value,
                count: record.aggregates[record.field].count,
                items: []
            };
            record.items.forEach(childitem => {
                groupModel.items.push(this.convertRecordForGrouping(childitem));
            });
            result = groupModel;
        } else {
            result = record;
        }

        return result;
    };
}