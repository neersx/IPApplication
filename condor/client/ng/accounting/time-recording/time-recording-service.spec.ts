import { HttpParams } from '@angular/common/http';
import { fakeAsync, tick } from '@angular/core/testing';
import { TimerSeed } from 'accounting/time-recording-widget/time-recording-timer-model';
import { HttpClientMock } from 'mocks';
import { KeepOnTopNotesViewService, KotViewProgramEnum } from 'rightbarnav/keep-on-top-notes-view.service';
import { RightBarNavServiceMock } from 'rightbarnav/rightbarnavservice.mock';
import { of } from 'rxjs';
import { debounceTime, distinctUntilChanged, switchMap } from 'rxjs/operators';
import * as _ from 'underscore';
import { Period, TimeEntry, TimeEntryEx, TimeRecordingPermissions, TimerEntries, WipStatusEnum } from './time-recording-model';
import { TimeRecordingService } from './time-recording-service';

describe('TimeRecordingService', () => {
    let httpClientSpy: any;
    let continuedTimeHelper: any;
    let service: TimeRecordingService;
    let rightBarNavService: RightBarNavServiceMock;
    let kotService: KeepOnTopNotesViewService;
    let timeOverlapsHelper: any;

    beforeEach(() => {
        rightBarNavService = new RightBarNavServiceMock();
        httpClientSpy = new HttpClientMock();
        httpClientSpy.get.mockReturnValue(of({}));
        httpClientSpy.post.mockReturnValue(of({}));
        httpClientSpy.put.mockReturnValue(of({}));
        continuedTimeHelper = { updateContinuedFlag: jest.fn().mockImplementation(data => data) };
        kotService = new KeepOnTopNotesViewService(httpClientSpy);
        timeOverlapsHelper = {updateOverlapStatus: jest.fn()};

        service = new TimeRecordingService(httpClientSpy, continuedTimeHelper, rightBarNavService as any, kotService, timeOverlapsHelper);
    });

    it('should exist', () => {
        expect(service).toBeDefined();
    });

    describe('getDefaultActivityFromCase', () => {
        it('calls the correct api', () => {
            service.getDefaultActivityFromCase(1234);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/accounting/time/activities/1234');
        });
    });
    describe('getDefaultNarrativeFromActivity', () => {
        it('calls the correct api if case is specified', () => {
            service.getDefaultNarrativeFromActivity('xyz', 1234);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/accounting/time/narrative', { params: { activityKey: 'xyz', caseKey: '1234', debtorKey: null, staffNameId: null } });
        });
        it('calls the correct api if only debtor is specified', () => {
            service.getDefaultNarrativeFromActivity('xyz', null, -101);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/accounting/time/narrative', { params: { activityKey: 'xyz', caseKey: null, debtorKey: '-101', staffNameId: null } });
        });
        it('calls the correct api if both case and debtor specified', () => {
            service.getDefaultNarrativeFromActivity('xyz', -555, -9876);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/accounting/time/narrative', { params: { activityKey: 'xyz', caseKey: '-555', debtorKey: null, staffNameId: null } });

            service.getDefaultNarrativeFromActivity('xyz', 0, -9876);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/accounting/time/narrative', { params: { activityKey: 'xyz', caseKey: '0', debtorKey: null, staffNameId: null } });
        });
        it('calls the correct api if neither case nor debtor are specified', () => {
            service.getDefaultNarrativeFromActivity('xyz');
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/accounting/time/narrative', { params: { activityKey: 'xyz', caseKey: null, debtorKey: null, staffNameId: null } });
        });
        it('calls the correct api if staffName is specified', () => {
            service.getDefaultNarrativeFromActivity('xyz', 1234, null, 987);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/accounting/time/narrative', { params: { activityKey: 'xyz', caseKey: '1234', debtorKey: null, staffNameId: '987' } });

            service.getDefaultNarrativeFromActivity('xyz', 1234, 567, 987);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/accounting/time/narrative', { params: { activityKey: 'xyz', caseKey: '1234', debtorKey: null, staffNameId: '987' } });
        });
    });

    describe('Update Entry Date', () => {
        it('calls the correct api', () => {
            const newDate = new Date(2000, 1, 1);
            const entry = new TimeEntryEx({ entryNo: 9876, entryDate: new Date() });
            const updated = { ...entry.makeServerReady(), ...{ entryDate: service.toLocalDate(newDate) } };
            service.updateDate(newDate, entry);
            expect(httpClientSpy.put).toHaveBeenCalledWith('api/accounting/time/updateDate', updated);
        });
        describe('To LocalDate', () => {
            it('returns local date, when date is passed', () => {
                const result = service.toLocalDate(new Date(2010, 11, 12, 11, 11, 9)).toISOString();

                expect(result).toEqual('2010-12-12T11:11:09.000Z');
            });
            it('returns only date, if dateOnly is required', () => {
                const result = service.toLocalDate(new Date(2010, 11, 12, 11, 11, 9), true).toISOString();

                expect(result).toEqual('2010-12-12T00:00:00.000Z');
            });
            it('returns null, when string is passed', () => {
                const result = service.toLocalDate('2010-12-11' as unknown as Date, true);

                expect(result).toBeNull();
            });
        });
    });

    describe('getUserPermissions', () => {
        it('returns no permissions, if staffId passed as null', done => {
            service.getUserPermissions(null).subscribe((data) => {
                expect(data).toEqual(new TimeRecordingPermissions());
                done();
            });
        });

        it('should make http request with passed staff id', done => {
            service.http.get = jest.fn().mockReturnValue(of({}));
            service.getUserPermissions(10).subscribe((data) => {
                expect(service.http.get).toHaveBeenCalledWith('api/accounting/time/permissions/10');
                done();
            });
        });

        it('should return TimeRecordingPermissions, received from server', done => {
            service.http.get = jest.fn().mockReturnValue(of({ canInsert: true }));

            service.getUserPermissions(10).subscribe((data) => {
                expect(data.canInsert).toBeTruthy();
                done();
            });
        });
    });

    describe('getTimeList', () => {
        const request = { selectedDate: new Date() };
        it('should mark item as incomplete when chargeRate is null', done => {
            const responseData = {
                data: {
                    data: [
                        {
                            caseKey: -457,
                            entryNo: 20,
                            chargeOutRate: null,
                            isIncomplete: false,
                            debtorSplits: null
                        },
                        {
                            caseKey: -457,
                            entryNo: 20,
                            chargeOutRate: null,
                            isIncomplete: false,
                            debtorSplits: [
                                { chargeOutRate: 100 },
                                { chargeOutRate: 110 }
                            ]
                        },
                        {
                            caseKey: -457,
                            entryNo: 20,
                            chargeOutRate: null,
                            isIncomplete: false,
                            debtorSplits: [
                                { chargeOutRate: 110, foreignCurrency: 'ABC' },
                                { chargeOutRate: 110, foreignCurrency: 'XyZ' }
                            ]
                        },
                        {
                            caseKey: -457,
                            entryNo: 20,
                            chargeOutRate: 100,
                            isIncomplete: true,
                            debtorSplits: [
                                { chargeOutRate: 110, foreignCurrency: 'ABC' },
                                { chargeOutRate: 110, foreignCurrency: 'XyZ' }
                            ]
                        }
                    ]
                }
            };
            service.http.get = jest.fn().mockReturnValue(of(responseData));

            service.getTimeList(request, null).subscribe((res: Array<TimeEntryEx>) => {
                expect(res[0].isIncomplete).toBe(true);
                expect(res[1].isIncomplete).toBe(false);
                expect(res[2].isIncomplete).toBe(false);
                expect(res[3].isIncomplete).toBe(true);
                done();
            });
        });

        it('should mark item as durationOnly when start & finish is null', done => {
            const responseData = {
                data: {
                    data: [
                        {
                            caseKey: -457,
                            entryNo: 20,
                            start: null,
                            finish: null
                        }
                    ]
                }
            };
            service.http.get = jest.fn().mockReturnValue(of(responseData));

            service.getTimeList(request, null).subscribe((res: any) => {
                expect(res[0].durationOnly).toBe(true);
                done();
            });
        });
        it('should initialise all required data and updated continued flag', done => {
            const responseData = {
                data: {
                    data: [new TimeEntryEx({ caseKey: 1, overlaps: false }), new TimeEntryEx({ caseKey: 2, overlaps: false })]
                }
            };
            service.http.get = jest.fn().mockReturnValue(of(responseData));
            service.getTimeList(request, null).subscribe(() => {
                expect(service.timeList).toEqual(responseData.data.data);
                expect(continuedTimeHelper.updateContinuedFlag).toHaveBeenCalled();
                expect(timeOverlapsHelper.updateOverlapStatus).toHaveBeenCalled();
                done();
            });
        });

    });
    describe('Evaluate Time', () => {
        it('should return the correct time entry', () => {
            service.timeList = [new TimeEntryEx({ entryNo: 1 }), new TimeEntryEx({ entryNo: 2 }), new TimeEntryEx({ entryNo: 3 })];
            const entryNo = 2;
            let timeEntry = service.getTimeEntryFromList(entryNo);
            expect(timeEntry.entryNo).toBe(entryNo);
            timeEntry = service.getTimeEntryFromList(null);
            expect(timeEntry.entryNo).toBe(1);
        });
        it('should make a call to get time entries from the list, when there is neither a case nor name', fakeAsync(() => {
            service.getTimeEntryFromList = jest.fn();
            service._configuretimeValuationRequest();
            service.timeValuationRequest.next({ caseKey: null, nameKey: null });
            tick(100);
            expect(service.getTimeEntryFromList).toHaveBeenCalled();
        }));
    });

    describe('Update Time Entry', () => {
        it('calls the correct API passing the parameters', () => {
            service.timeList = [new TimeEntryEx({ entryNo: 1234, parentEntryNo: 1 })];
            service.updateTimeEntry({ entryNo: 1234, activityKey: 'ABC-xyz' });
            expect(httpClientSpy.put).toHaveBeenCalledWith('api/accounting/time/update', { entryNo: 1234, activityKey: 'ABC-xyz', parentEntryNo: 1 });
        });
    });

    describe('Adding Time Entry', () => {
        it('calls the correct API passing the parameters', () => {
            service.saveTimeEntry({ caseKey: 1234, activityKey: 'ABC-xyz' });
            expect(httpClientSpy.post).toHaveBeenCalledWith('api/accounting/time/save', { caseKey: 1234, activityKey: 'ABC-xyz' });
        });
    });

    describe('Deleting Time Entry', () => {
        it('calls the correct API passing the parameters', () => {
            const entry1 = new TimeEntryEx({ entryNo: 987 });
            service.deleteTimeEntry(entry1);
            expect(httpClientSpy.request).toHaveBeenCalled();
            expect(httpClientSpy.request.mock.calls[0][0]).toBe('delete');
            expect(httpClientSpy.request.mock.calls[0][1]).toBe('api/accounting/time/delete');
            expect(httpClientSpy.request.mock.calls[0][2]).toEqual({ body: entry1 });

            const entry2 = new TimeEntryEx({ entryNo: 987, staffNameId: -101 });
            service.deleteTimeEntry(entry2);
            expect(httpClientSpy.request).toHaveBeenCalledTimes(2);
            expect(httpClientSpy.request.mock.calls[1][2]).toEqual({ body: entry2 });
        });
        it('calls API for deleteing posted entry', () => {
            const entry1 = new TimeEntryEx({ entryNo: 987, isPosted: true });
            service.deleteTimeEntry(entry1);
            expect(httpClientSpy.request).toHaveBeenCalled();
            expect(httpClientSpy.request.mock.calls[0][0]).toBe('delete');
            expect(httpClientSpy.request.mock.calls[0][1]).toBe('api/accounting/posted-time/delete');
            expect(httpClientSpy.request.mock.calls[0][2]).toEqual({ body: entry1 });
        });

        it('calls the correct API, for deleting entry from continued chain', () => {
            const entry1 = new TimeEntryEx({ entryNo: 987, parentEntryNo: 100 });
            service.deleteTimeEntry(entry1);
            expect(httpClientSpy.request.mock.calls[0][1]).toBe('api/accounting/time/delete-from-chain');
        });

        it('calls the correct API, for deleting entry from posted continued chain', () => {
            const entry1 = new TimeEntryEx({ entryNo: 987, parentEntryNo: 100, isPosted: true });
            service.deleteTimeEntry(entry1);
            expect(httpClientSpy.request.mock.calls[0][1]).toBe('api/accounting/posted-time/delete-from-chain');
        });
    });

    describe('Deleting Continued Chain', () => {
        it('calls the correct API passing the parameters', () => {
            const entry = new TimeEntryEx({ entryNo: 987 });
            service.deleteContinuedChain(entry);
            expect(httpClientSpy.request).toHaveBeenCalledWith('delete', 'api/accounting/time/delete-chain', { body: entry });
        });

        it('calls the correct API for deleting posted chain passing the parameters', () => {
            const entry = new TimeEntryEx({ entryNo: 987, isPosted: true });
            service.deleteContinuedChain(entry);
            expect(httpClientSpy.request).toHaveBeenCalledWith('delete', 'api/accounting/posted-time/delete-chain', { body: entry });
        });
    });

    describe('timer related functions', () => {
        it('start timer calls server with details', () => {
            const seed = new TimerSeed({ startDateTime: new Date(), staffNameId: 100 });
            service.startTimer(seed);

            expect(httpClientSpy.post).toHaveBeenCalledWith('api/accounting/timer/start', seed);
        });
        it('start timer calls continue API where specified', () => {
            const seed = new TimerSeed({ startDateTime: new Date(), staffNameId: 98765 });
            service.startTimer(seed, true);

            expect(httpClientSpy.post).toHaveBeenCalledWith('api/accounting/timer/continue', seed);
        });

        it('start timer applies stop timer details', () => {
            const timerEntries = new TimerEntries({
                stoppedTimer: new TimeEntryEx({ chargeOutRate: 99, finish: '1/1/2010', entryNo: 10 })
            });

            httpClientSpy.post = jest.fn().mockReturnValue(of(timerEntries));
            service.timeList = [{ entryNo: 10 }];

            service.startTimer(new TimerSeed({})).subscribe();

            expect(service.timeList[0].finish).toEqual(new Date('1/1/2010'));
            expect(service.timeList[0].chargeOutRate).toEqual(99);
            expect(service.timeList[0].isTimer).toBeFalsy();
        });

        it('stop timer calls server with details', () => {
            const entry = new TimeEntry();
            service.stopTimer(entry);

            expect(httpClientSpy.put).toHaveBeenCalledWith('api/accounting/timer/stop', entry);
        });

        it('stop timer applies recieved details', () => {
            const entryFromServer = new TimeEntryEx({ start: '1/2/2010', chargeOutRate: 100 });
            httpClientSpy.put = jest.fn().mockReturnValue(of({ response: { timeEntry: entryFromServer, entryNo: 10 } }));
            service.timeList = [{ entryNo: 10 }];

            service.stopTimer({ entryNo: 10 }).subscribe();

            expect(service.timeList[0].start).toEqual(new Date('1/2/2010'));
            expect(service.timeList[0].chargeOutRate).toEqual(100);
            expect(service.timeList[0].isTimer).toBeFalsy();
        });

        it('save timer calls server with details', () => {
            const entry = new TimeEntry();
            service.saveTimer(entry, true);

            expect(httpClientSpy.put).toHaveBeenCalledWith('api/accounting/timer/save', {
                timeEntry: entry,
                stopTimer: true
            });
        });

        it('save timer applies recieved details', () => {
            const entryFromServer = new TimeEntryEx({ start: '1/2/2010', chargeOutRate: 100 });
            httpClientSpy.put = jest.fn().mockReturnValue(of({ response: { timeEntry: entryFromServer, entryNo: 10 } }));
            service.timeList = [{ entryNo: 10 }];

            service.saveTimer({ entryNo: 10 }).subscribe();

            expect(service.timeList[0].start).toEqual(new Date('1/2/2010'));
            expect(service.timeList[0].chargeOutRate).toEqual(100);
            expect(service.timeList[0].isTimer).toBeFalsy();
        });

        it('reset timer makes the correct server call', () => {
            const entry = new TimeEntry();
            service.resetTimerEntry(entry);

            expect(httpClientSpy.put).toHaveBeenCalledWith('api/accounting/timer/reset', entry);
        });
    });
    describe('helper functions', () => {
        it('getTimeEntryFromList returns correct entry if entryNo is defined', () => {
            const entry100 = new TimeEntryEx({ entryNo: 100 });
            service.timeList = [entry100];

            const result = service.getTimeEntryFromList(100);
            expect(result).toEqual(entry100);

            expect(service.getTimeEntryFromList(10)).toBeUndefined();
        });

        it('getTimeEntryFromList returns first entry if entryNo is not provided', () => {
            const entry100 = new TimeEntryEx({ entryNo: 100 });
            service.timeList = [entry100, new TimeEntryEx({ entryNo: 200 })];

            const result = service.getTimeEntryFromList(null);
            expect(result).toEqual(entry100);
        });

        it('get index for the entryNo', () => {
            service.timeList = [new TimeEntryEx({ entryNo: 100 }), new TimeEntryEx({ entryNo: 200 }), new TimeEntryEx({ entryNo: 300 })];

            const result = service.getRowIdFor(200);
            expect(result).toEqual(1);
        });
    });

    describe('canPostedEntryBeEdited calls correct API', () => {
        it('calls correct API and returns value', done => {
            httpClientSpy.get = jest.fn().mockReturnValue(of(WipStatusEnum.Billed));

            service.canPostedEntryBeEdited(10, 100).subscribe((result) => {
                expect(result).toEqual('billed');
                done();
            });
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/accounting/warnings/editableStatus/10/100');
        });
    });

    describe('getOpenPeriods', () => {
        it('calls correct API', () => {
            const list = new Array<Period>();
            list.push(new Period({ startTime: new Date(2010, 1, 1) }));
            list.push(new Period({ startTime: new Date(2011, 1, 1) }));

            httpClientSpy.get = jest.fn().mockReturnValue(of(list));

            service.getOpenPeriods().subscribe((result) => {
                expect(result.length).toBe(2);
                expect(result[0]).toEqual(list[0]);
                expect(result[1]).toEqual(list[1]);
            });
        });
    });

    describe('show keep on top notes', () => {
        it('get Kot notes', () => {
            service.showKeepOnTopNotes();
            service.kot.pipe(
                debounceTime(300),
                distinctUntilChanged(),
                switchMap(selected => {
                    expect(rightBarNavService.registerKot).toBeCalledWith(null);
                    expect(kotService.getKotForCaseView).toBeCalled();
                    expect(selected).toBeDefined();
                })
            );
            kotService.getKotForCaseView('123', KotViewProgramEnum.Case).subscribe((res) => {
                expect(res).toBeDefined();
                expect(rightBarNavService.registerKot).toBeCalled();
            });
        });
    });
});
