import { Injectable } from '@angular/core';
import * as _ from 'underscore';
import { TimeEntryEx } from '../time-recording-model';

@Injectable()
export class ContinuedTimeHelper {

    updateContinuedFlag(timeList: Array<TimeEntryEx>): void {
        const parentEntryNos = _.pluck(timeList, 'parentEntryNo').filter(x => !!x);
        const allPotentialChildren = _.filter(timeList, (entry) => {
            return !_.contains(parentEntryNos, entry.entryNo);
        });

        _.each(allPotentialChildren, (d: TimeEntryEx) => {
            if (d.parentEntryNo !== 0 && !d.parentEntryNo) { return; }
            d.isLastChild = true;
            this._setChildEntryNoAndStatus(timeList, d.parentEntryNo, d.entryNo, d.isPosted);
        });
    }

    _setChildEntryNoAndStatus(timeList: Array<TimeEntryEx>, parentEntryNo: number, childEntryNo: number, isPosted: boolean): void {
        if (parentEntryNo !== 0 && !parentEntryNo) {
            return;
        }
        const directParent = _.findWhere(timeList, { entryNo: parentEntryNo });
        if (directParent) {
            directParent.childEntryNo = childEntryNo;
            directParent.isContinuedParent = true;
            directParent.chargeOutRate = null;
            directParent.isPosted = isPosted;
            directParent.isIncomplete = false;
            this._setChildEntryNoAndStatus(timeList, directParent.parentEntryNo, childEntryNo, isPosted);
        }
    }
}