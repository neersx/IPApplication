import { fakeAsync, tick } from '@angular/core/testing';
import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { DateFunctions } from 'shared/utilities/date-functions';
import { TimeEntry } from '../time-recording-model';
import { BatchSelectionDetails, ReverseSelection, TimeRecordingQueryData } from './time-recording-query-model';
import { TimeSearchService } from './time-search.service';

let http: any;
let continuedTimeHelper: any;
let localeDatePipe: any;
let service: TimeSearchService;

describe('Service: TimeSearch', () => {

    beforeEach(() => {
        http = new HttpClientMock();
        http.get = jest.fn().mockReturnValue(of({
            data: { data: [new TimeEntry(), new TimeEntry()] },
            timeSummary: { totalHours: 123456, totalValue: 2345.67, totalDiscount: 34.56 }
        }));
        continuedTimeHelper = { updateContinuedFlag: jest.fn() };
        localeDatePipe = { transform: jest.fn() };
        service = new TimeSearchService(http, continuedTimeHelper, localeDatePipe);
    });

    it('should create an instance', () => {
        expect(service).toBeTruthy();
    });

    describe('Run Search', () => {
        it('calls the correct api', () => {
            const input = new TimeRecordingQueryData({ staff: { key: 1234 }, fromDate: new Date(), toDate: new Date() });
            service.runSearch$(input, { sortBy: 'a', take: 1 });
            expect(http.get.mock.calls[0][0]).toEqual('api/accounting/time/search');
            expect(JSON.parse(http.get.mock.calls[0][1].params.params).sortBy).toEqual('a');
            expect(JSON.parse(http.get.mock.calls[0][1].params.params).take).toEqual(1);
            expect(JSON.parse(http.get.mock.calls[0][1].params.q).staffId).toEqual(1234);
            expect(JSON.parse(http.get.mock.calls[0][1].params.q).fromDate).toContain('T00:00:00.000Z');
            expect(JSON.parse(http.get.mock.calls[0][1].params.q).toDate).toContain('T00:00:00.000Z');
        });
        it('extracts the filters from the input', () => {
            const input = new TimeRecordingQueryData({
                staff: { key: 1234 },
                fromDate: new Date(),
                toDate: new Date(),
                activity: { key: 'MTV', value: 'Music Tele Vision' },
                cases: [{ key: 123, caseRef: '1234A' }, { key: 234, caseRef: '234A' }],
                name: { key: 567, displayName: 'The Debtor' }
            });
            service.runSearch$(input, { sortBy: 'a', take: 1 });
            expect(http.get.mock.calls[0][0]).toEqual('api/accounting/time/search');
            expect(JSON.parse(http.get.mock.calls[0][1].params.q).staffId).toEqual(1234);
            expect(JSON.parse(http.get.mock.calls[0][1].params.q).activityId).toEqual('MTV');
            expect(JSON.parse(http.get.mock.calls[0][1].params.q).caseIds).toEqual([123, 234]);
            expect(JSON.parse(http.get.mock.calls[0][1].params.q).nameId).toEqual(567);
            expect(JSON.parse(http.get.mock.calls[0][1].params.q).fromDate).toContain('T00:00:00.000Z');
            expect(JSON.parse(http.get.mock.calls[0][1].params.q).toDate).toContain('T00:00:00.000Z');
        });
        it('sets the time summary values', done => {
            service.runSearch$(new TimeRecordingQueryData(), { sortBy: 'a', take: 1, skip: 0 }).subscribe(() => {
                service.timeSummary$.subscribe((value) => {
                    expect(value).toEqual(expect.objectContaining({ totalHours: 123456, totalValue: 2345.67, totalDiscount: 34.56 }));
                });
                done();
            });
        });

        it('maps selected null filters to blank values before calling api', done => {
            const filters = [{ value: 'null,a', field: 'some' }];
            service.runSearch$(new TimeRecordingQueryData(), { sortBy: 'a', take: 1, filters }).subscribe(() => {
                expect(JSON.parse(http.get.mock.calls[0][1].params.params).filters[0]).toEqual({ value: 'a,', field: 'some' });
                done();
            });
        });

        it('considers summary values only for the first page', done => {
            const nextSpy = jest.spyOn(service.timeSummary$, 'next');
            service.runSearch$(new TimeRecordingQueryData(), { sortBy: 'a', take: 1, skip: 10 }).subscribe(() => {
                expect(nextSpy).not.toHaveBeenCalled();
                done();
            });
        });
    });

    describe('Get initial data', () => {
        it('calls the correct api', () => {
            service.searchParamData$();
            expect(http.get).toHaveBeenCalledWith('api/accounting/time/search/view');
        });

        describe('filters', () => {
            it('calls api with the last search performed', fakeAsync(() => {
                const queryData = new TimeRecordingQueryData();
                queryData.staff = { key: 1234 };
                queryData.fromDate = new Date();
                queryData.toDate = new Date();
                queryData.activity = { key: 'MTV', value: 'Music Tele Vision' };
                queryData.cases = [{ key: 123, caseRef: '1234A' }, { key: 234, caseRef: '234A' }];
                queryData.name = { key: 567, displayName: 'The Debtor' };

                const queryParams = { sortBy: 'a', take: 1, skip: 0 };
                service.runSearch$(queryData, queryParams).subscribe();
                tick();
                service.runFilterMetaSearch$('start');

                expect(http.get.mock.calls[1][0]).toEqual('api/accounting/time/search/filterData/start');
                expect(JSON.parse(http.get.mock.calls[1][1].params.q).staffId).toEqual(1234);
                expect(JSON.parse(http.get.mock.calls[1][1].params.q).activityId).toEqual('MTV');
                expect(JSON.parse(http.get.mock.calls[1][1].params.q).caseIds).toEqual([123, 234]);
                expect(JSON.parse(http.get.mock.calls[1][1].params.q).nameId).toEqual(567);
                expect(JSON.parse(http.get.mock.calls[1][1].params.q).fromDate).toContain('T00:00:00.000Z');
                expect(JSON.parse(http.get.mock.calls[1][1].params.q).toDate).toContain('T00:00:00.000Z');
            }));
            it('calls api to get fiter metadata', () => {
                service.runFilterMetaSearch$('caseReference');
                expect(http.get.mock.calls[0][0]).toEqual('api/accounting/time/search/filterData/caseReference');
            });

            it('maps filter metadata recieved for search dates', done => {
                const date1 = '1-1-2010';
                const date2 = '4-4-2012';
                const data = [{ description: date1 }, { description: date2 }];
                localeDatePipe.transform = jest.fn().mockReturnValueOnce(date1).mockReturnValue(date2);
                http.get = jest.fn().mockReturnValue(of(data));
                service.runFilterMetaSearch$('entryDate').subscribe((r) => {
                    expect(r.length).toEqual(2);
                    expect(r[0].code).toEqual(DateFunctions.toLocalDate(new Date(date1), true).toISOString());
                    expect(r[0].description).toEqual(date1);

                    expect(r[1].code).toEqual(DateFunctions.toLocalDate(new Date(date2), true).toISOString());
                    expect(r[1].description).toEqual(date2);
                    done();
                });
            });

            it('maps null values receieved for caseReference, name and activity', (done) => {
                const data = [{ code: '', description: 'ABCD' }, { code: 'a', description: 'XYZA' }];

                http.get = jest.fn().mockReturnValue(of(data));
                service.runFilterMetaSearch$('caseReference').subscribe((r) => {
                    expect(r.length).toEqual(2);
                    expect(r[0].code).toEqual('null');
                    expect(r[0].description).toEqual('ABCD');

                    expect(r[0].code).toEqual('null');
                    expect(r[0].description).toEqual('ABCD');
                    done();
                });
            });
        });
    });

    describe('Exporting', () => {
        it('should call the correct api', () => {
            const input = new TimeRecordingQueryData({ staff: { key: 1234 }, fromDate: new Date(), toDate: new Date() });
            service.exportSearch$(input, { sortBy: 'a', take: 1 }, 'Pdf', null, -1234);
            expect(http.post.mock.calls[0][0]).toEqual('api/accounting/time/search/export');
            expect(http.post.mock.calls[0][1].searchParams).toEqual(expect.objectContaining({ staffId: 1234 }));
            expect(http.post.mock.calls[0][1].searchParams).toEqual(expect.objectContaining({ fromDate: DateFunctions.toLocalDate(new Date(), true) }));
            expect(http.post.mock.calls[0][1].searchParams).toEqual(expect.objectContaining({ toDate: DateFunctions.toLocalDate(new Date(), true) }));
            expect(http.post.mock.calls[0][1].exportFormat).toBe('Pdf');
            expect(http.post.mock.calls[0][1].contentId).toBe(-1234);
        });
    });

    describe('Delete', () => {
        it('should make server call to correct api', () => {
            const details = new BatchSelectionDetails({ staffNameId: 10, entryNumbers: [1, 2], reverseSelection: new ReverseSelection(null, null) });
            service.deleteEntries(details);

            expect(http.request).toHaveBeenCalled();
            expect(http.request.mock.calls[0][0]).toEqual('delete');
            expect(http.request.mock.calls[0][1]).toEqual('api/accounting/time/batch/delete');
            expect(http.request.mock.calls[0][2].body).not.toBeNull();
            expect(http.request.mock.calls[0][2].body.staffNameId).toBe(details.staffNameId);
            expect(http.request.mock.calls[0][2].body.entryNumbers).toEqual(details.entryNumbers);
            expect(http.request.mock.calls[0][2].body.reverseSelection).toEqual(details.reverseSelection);
        });
    });

    describe('UpdateNarrative', () => {
        it('calls the server with correct parameters', () => {
            const selection = new BatchSelectionDetails({});
            const newNarrative = { some: 'thing' };
            service.updateNarrative(selection, newNarrative);

            expect(http.request).toHaveBeenCalled();
            expect(http.request).toHaveBeenCalled();
            expect(http.request.mock.calls[0][0]).toEqual('put');
            expect(http.request.mock.calls[0][1]).toEqual('api/accounting/time/batch/update-narrative');
            expect(http.request.mock.calls[0][2].body).not.toBeNull();
            expect(http.request.mock.calls[0][2].body.selectiondetails).toBe(selection);
            expect(http.request.mock.calls[0][2].body.newNarrative).toEqual(newNarrative);
        });
    });

    describe('recent entries', () => {
        it('calls api with correct parameters', () => {
            service.recentEntries$(10, {});
            expect(http.get).toHaveBeenCalled();
            expect(http.get.mock.calls[0][0]).toBe('api/accounting/time/search/recent-entries');
            expect(JSON.parse(http.get.mock.calls[0][1].params.q).staffId).toBe(10);
        });
    });
});