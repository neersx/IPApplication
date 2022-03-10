import * as _ from 'underscore';
import { TimeEntryEx } from '../time-recording-model';
import { TimeOverlapsHelper } from './time-overlaps-helper';

describe('TimeOverlaps Helper', () => {
    let subject: TimeOverlapsHelper;

    beforeEach(() => {
        subject = new TimeOverlapsHelper();
    });
    it('should create an instance', () => {
        expect(subject).toBeTruthy();
    });

    describe('update overlaps status', () => {
        let data: Array<TimeEntryEx> = [];
        beforeEach(() => {
            data = [
                new TimeEntryEx({ entryNo: 1, start: new Date(2000, 12, 12, 8, 0, 0), finish: new Date(2000, 12, 12, 8, 30, 0) }),
                new TimeEntryEx({ entryNo: 2, start: new Date(2000, 12, 12, 8, 30, 0), finish: new Date(2000, 12, 12, 9, 0, 0) }),
                new TimeEntryEx({ entryNo: 3, start: new Date(2000, 12, 12, 9, 0, 0), finish: new Date(2000, 12, 12, 9, 30, 0) })
            ];
        });

        it('does not mark non-overlapping times', () => {
            subject.updateOverlapStatus(data);
            expect(_.pluck(data, 'overlaps')).toEqual([false, false, false]);
        });
        it('marks time where starts and finishes within another entry', () => {
            data.push(new TimeEntryEx({ entryNo: 4, start: new Date(2000, 12, 12, 9, 10, 0), finish: new Date(2000, 12, 12, 9, 15, 0)}));
            subject.updateOverlapStatus(data);
            expect(_.pluck(data, 'overlaps')).toEqual([false, false, true, true]);
        });
        it('marks time where it finishes after another entry starts', () => {
            data.push(new TimeEntryEx({ entryNo: 4, start: new Date(2000, 12, 12, 7, 30, 0), finish: new Date(2000, 12, 12, 8, 0, 1) }));
            subject.updateOverlapStatus(data);
            expect(_.pluck(data, 'overlaps')).toEqual([true, false, false, true]);
        });
        it('marks time where it starts before another entry finishes', () => {
            data.push(new TimeEntryEx({ entryNo: 4, start: new Date(2000, 12, 12, 9, 29, 59), finish: new Date(2000, 12, 12, 9, 30, 0) }));
            data.push(new TimeEntryEx({ entryNo: 5, parentEntryNo: 4, start: new Date(2000, 12, 12, 9, 29, 59), finish: new Date(2000, 12, 12, 9, 30, 10) }));
            subject.updateOverlapStatus(data);
            expect(_.pluck(data, 'overlaps')).toEqual([false, false, true, true, true]);
        });
        it('ignores running timers', () => {
            data.push(new TimeEntryEx({ entryNo: 4, start: new Date(2000, 12, 12, 9, 10, 0), finish: null, isTimer: true }));
            subject.updateOverlapStatus(data);
            expect(_.pluck(data, 'overlaps')).toEqual([false, false, false, false]);
        });
    });
});
