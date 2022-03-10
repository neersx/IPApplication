import { Injectable } from '@angular/core';
import * as _ from 'underscore';
import { TimeEntryEx } from '../time-recording-model';

@Injectable()
export class TimeOverlapsHelper {

    updateOverlapStatus(timeList: Array<TimeEntryEx>): void {
        _.map(timeList, (item: TimeEntryEx) => {
            item.overlaps = !item.isTimer &&
                _.any(_.filter(timeList, (time: TimeEntryEx) => {
                    return !time.isTimer && !!time.finish && !!time.start;
                }),
                    (other: TimeEntryEx) => {
                        return item.start > other.start && item.start < other.finish ||
                            item.finish > other.start && item.finish < other.finish ||
                            item.start < other.start && item.finish >= other.finish ||
                            item.start <= other.start && item.finish > other.finish;
                    });
        });
    }
}
