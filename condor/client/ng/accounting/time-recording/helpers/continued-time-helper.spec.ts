import * as _ from 'underscore';
import { TimeEntryEx } from '../time-recording-model';
import { ContinuedTimeHelper } from './continued-time-helper';

describe('updateCanDeleteFlag', () => {
    let service: ContinuedTimeHelper;

    beforeEach(() => {
        service = new ContinuedTimeHelper();
    });

    it('should create an instance', () => {
        expect(service).toBeTruthy();
    });
    describe('when there are continued entries', () => {
        it('should update IsContinued flag appropriately', () => {
            const timeList: Array<TimeEntryEx> = [
                { caseKey: -457, entryNo: 20, parentEntryNo: null },
                { caseKey: 13, entryNo: 22, parentEntryNo: null },
                { caseKey: 13, entryNo: 21, parentEntryNo: null },
                { caseKey: -457, entryNo: 23, parentEntryNo: null },
                { caseKey: -457, entryNo: 24, parentEntryNo: 23 },
                { caseKey: 13, entryNo: 25, parentEntryNo: 22 },
                { caseKey: 487, entryNo: 26, parentEntryNo: null }
            ];
            service.updateContinuedFlag(timeList);
            expect(timeList.find(x => x.entryNo === 23).isContinuedParent).toBe(true);
            expect(timeList.find(x => x.entryNo === 22).isContinuedParent).toBe(true);
            expect(timeList.find(x => x.entryNo === 25).isLastChild).toBeTruthy();
        });

        const data: Array<TimeEntryEx> = [
            new TimeEntryEx({ entryNo: 1, chargeOutRate: 100, isLastChild: false, isIncomplete: true }),
            new TimeEntryEx({ entryNo: 2, parentEntryNo: 1, chargeOutRate: 100, isLastChild: false, isIncomplete: true }),
            new TimeEntryEx({ entryNo: 3, parentEntryNo: 2, chargeOutRate: 100, isPosted: true, isLastChild: false, isIncomplete: true }),
            new TimeEntryEx({ entryNo: 4, chargeOutRate: 200, isPosted: false, isLastChild: false, isIncomplete: true })
        ];
        it('should clear chargeOutRate for continued entries', () => {
            service.updateContinuedFlag(data);
            expect(_.pluck(data, 'chargeOutRate')).toEqual([null, null, 100, 200]);
        });
        it('should clear isIncomplete flag from continued entries', () => {
            service.updateContinuedFlag(data);
            expect(_.pluck(data, 'isIncomplete')).toEqual([false, false, true, true]);
        });
        it('should mark isPosted flag for parent entries', () => {
            service.updateContinuedFlag(data);
            expect(_.pluck(data, 'isPosted')).toEqual([true, true, true, false]);
        });
        it('should mark isContinuedParent flag for parent entries', () => {
            service.updateContinuedFlag(data);
            expect(_.pluck(data, 'isContinuedParent')).toEqual([true, true, undefined, undefined]);
        });
        it('should set childEntryNo for parent entries', () => {
            service.updateContinuedFlag(data);
            expect(_.pluck(data, 'childEntryNo')).toEqual([3, 3, null, null]);
        });
        it('should set isLastChild for last entries in continued chain', () => {
            service.updateContinuedFlag(data);
            expect(_.pluck(data, 'isLastChild')).toEqual([false, false, true, false]);
        });
    });
});