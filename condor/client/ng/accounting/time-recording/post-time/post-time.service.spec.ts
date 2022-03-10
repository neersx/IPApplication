import { HttpClientMock, IpxNotificationServiceMock } from 'mocks';
import { of } from 'rxjs';
import { PostTimeService } from './post-time.service';

const date1 = new Date(2000, 1, 1);
const date2 = new Date(1999, 1, 1);
let service: PostTimeService;
let http: any;
let notificationService: IpxNotificationServiceMock;

beforeEach(() => {
    http = new HttpClientMock();
    http.get = jest.fn().mockReturnValue(of({ data: [{ date: date1 }, { date: date2 }] }));
    http.post = jest.fn().mockReturnValue(of({}));
    notificationService = new IpxNotificationServiceMock();
    service = new PostTimeService(http, notificationService as any);
});

describe('Get postable dates', () => {
    it('should call the correct url for the request', () => {
        service.getDates(null);
        expect(http.get).toHaveBeenCalledWith('api/accounting/time-posting/getDates',
            {
                params: {
                    params: JSON.stringify({
                        skip: 0,
                        take: 10
                    }),
                    dates: JSON.stringify({
                        from: null,
                        to: null
                    })
                }
            });
    });
    it('should call the correct url for the post all staff request', () => {
        const fromDate = new Date();
        const toDate = new Date();
        fromDate.setDate(toDate.getDate() - 5);
        service.getDates(null, null, fromDate, toDate, false);
        expect(http.get).toHaveBeenCalledWith('api/accounting/time-posting/getDates',
            {
                params: {
                    params: JSON.stringify({
                        skip: 0,
                        take: 10
                    }),
                    dates: JSON.stringify({
                        from: null,
                        to: null
                    })
                }
            });
            service.getDates(null, null, fromDate, toDate, true);
            expect(http.get).toHaveBeenCalledWith('api/accounting/time-posting/getDates',
                {
                    params: {
                        params: JSON.stringify({
                            skip: 0,
                            take: 10
                        }),
                        dates: JSON.stringify({
                            from: fromDate,
                            to: toDate
                        })
                    }
                });
    });
    it('should get for selected staffName where required', () => {
        service.getDates(null, -98765);
        expect(http.get).toHaveBeenCalledWith('api/accounting/time-posting/getDates/-98765',
            {
                params: {
                    params: JSON.stringify({
                        skip: 0,
                        take: 10
                    }),
                    dates: JSON.stringify({
                        from: null,
                        to: null
                    })
                }
            });

        service.getDates(null, 0);
        expect(http.get).toHaveBeenCalledWith('api/accounting/time-posting/getDates/0',
            {
                params: {
                    params: JSON.stringify({
                        skip: 0,
                        take: 10
                    }),
                    dates: JSON.stringify({
                        from: null,
                        to: null
                    })
                }
            });
    });
    it('should return the list of dates in expected form', done => {
        service.getDates(null).subscribe(result => {
            done();
            expect(result).toEqual({ data: [{ rowKey: date1, date: date1 }, { rowKey: date2, date: date2 }] });
        });
    });
});

describe('posting a single time entry', () => {
    it('should call the correct url for posting', () => {
        const data = { key: 1234, value: 'abc-XYZ' };
        service.postSelectedEntry(data);
        expect(http.post).toHaveBeenCalledWith('api/accounting/time-posting/postEntry', data);
    });

    it('displays confirmation modal in case of warning', done => {
        const successResult = { result: 'Awesome!' };
        http.post = jest.fn().mockReturnValueOnce(of({ hasWarning: true, rowPosted: 0, error: { alertID: 'ABCD' } })).mockReturnValueOnce(of(successResult));
        notificationService.modalRef.content = { confirmed$: of(true) };
        const postEntry = {};
        service.postResult$.subscribe(res => {
            expect(res).toEqual(successResult);
            done();
        });
        service.postSelectedEntry(postEntry);

        expect(http.post).toHaveBeenCalledTimes(2);
        expect(http.post.mock.calls[0][0]).toEqual('api/accounting/time-posting/postEntry');
        expect(http.post.mock.calls[0][1]).toEqual(postEntry);
        expect(http.post.mock.calls[1][0]).toEqual('api/accounting/time-posting/postEntry');
        expect(http.post.mock.calls[1][1]).toEqual({ ...postEntry, warningAccepted: true });

        expect(notificationService.openConfirmationModal).toHaveBeenCalled();
        expect(notificationService.openConfirmationModal.mock.calls[0][0]).toEqual('Warning');
        expect(notificationService.openConfirmationModal.mock.calls[0][1]).toEqual('accounting.errors.ABCD');
        expect(notificationService.openConfirmationModal.mock.calls[0][2]).toEqual('Proceed');
        expect(notificationService.openConfirmationModal.mock.calls[0][3]).toEqual('Cancel');
    });

    it('does not proceed with post if user does nto provide confirmation', () => {
        http.post = jest.fn().mockReturnValueOnce(of({ hasWarning: true, rowPosted: 0, error: { alertID: 'ABCD' } }));
        notificationService.modalRef.content = { confirmed$: of() };
        const postEntry = {};
        service.postSelectedEntry(postEntry);

        expect(http.post).toHaveBeenCalledTimes(1);
    });
});

describe('posting multiple entries', () => {
    const url = 'api/accounting/time-posting/post';
    it('should set the staffNameId where available', () => {
        const localDate1 = { date: new Date(1899, 0, 1) };
        const localDate2 = { date: new Date(1899, 0, 2) };
        service.postTime(-19628, [localDate1, localDate2]);
        expect(http.post).toHaveBeenCalledWith(url, { entityKey: -19628, selectedDates: [localDate1.date, localDate2.date], staffNameId: undefined });
    });

    it('displays confirmation modal in case of warning', done => {
        const successResult = { result: 'Awesome!' };
        http.post = jest.fn().mockReturnValueOnce(of({ hasWarning: true, rowPosted: 0, error: { alertID: 'ABCD' } })).mockReturnValueOnce(of(successResult));
        notificationService.modalRef.content = { confirmed$: of(true) };
        const postEntries = { entityKey: 1000, selectedDates: [new Date(1899, 0, 1), new Date(1899, 0, 2)], staffNameId: 10 };
        service.postResult$.subscribe(res => {
            expect(res).toEqual(successResult);
            done();
        });
        service.postTime(postEntries.entityKey, postEntries.selectedDates, postEntries.staffNameId);

        expect(http.post).toHaveBeenCalledTimes(2);
        expect(http.post.mock.calls[1][0]).toEqual('api/accounting/time-posting/post');
        expect(http.post.mock.calls[1][1]).toEqual({ ...postEntries, warningAccepted: true });

        expect(notificationService.openConfirmationModal).toHaveBeenCalled();
        expect(notificationService.openConfirmationModal.mock.calls[0][0]).toEqual('Warning');
        expect(notificationService.openConfirmationModal.mock.calls[0][1]).toEqual('accounting.errors.ABCD');
        expect(notificationService.openConfirmationModal.mock.calls[0][2]).toEqual('Proceed');
        expect(notificationService.openConfirmationModal.mock.calls[0][3]).toEqual('Cancel');
    });

    it('does not proceed with post if user does nto provide confirmation', () => {
        http.post = jest.fn().mockReturnValueOnce(of({ hasWarning: true, rowPosted: 0, error: { alertID: 'ABCD' } }));
        notificationService.modalRef.content = { confirmed$: of() };
        const postEntries = { entityKey: 1000, selectedDates: [new Date(1899, 0, 1), new Date(1899, 0, 2)], staffNameId: 10 };
        service.postTime(postEntries.entityKey, postEntries.selectedDates, postEntries.staffNameId);

        expect(http.post).toHaveBeenCalledTimes(1);
    });
});

describe('postForAllStaff', () => {
    const url = 'api/accounting/time-posting/postForAllStaff';
    const fromDate = new Date();
    const toDate = new Date();
    it('should call with correct params and dates', () => {
        fromDate.setDate(toDate.getDate() - 5);
        service.postForAllStaff(-111, null, fromDate, toDate);
        expect(http.post).toHaveBeenCalledWith(url, {entityKey: -111,
            selectedDates: null,
            warningAccepted: false,
            searchParams: {
                fromDate,
                toDate
            }});
    });
    it('displays confirmation modal in case of warning', done => {
        const successResult = { result: 'success' };
        http.post = jest.fn().mockReturnValueOnce(of({ hasWarning: true, rowPosted: 0, error: { alertID: 'ABCD' } })).mockReturnValueOnce(of(successResult));
        notificationService.modalRef.content = { confirmed$: of(true) };
        const postEntries = {
            entityKey: -111,
            selectedDates: [new Date(1899, 0, 1), new Date(1899, 0, 2)],
            warningAccepted: false,
            searchParams: {
                fromDate,
                toDate
            }
        };
        service.postResult$.subscribe(res => {
            expect(res).toEqual(successResult);
            done();
        });
        service.postForAllStaff(postEntries.entityKey, postEntries.selectedDates, postEntries.searchParams.fromDate, postEntries.searchParams.toDate);
        expect(http.post).toHaveBeenCalledTimes(2);
        expect(http.post.mock.calls[1][0]).toEqual(url);
        expect(http.post.mock.calls[1][1]).toEqual({ ...postEntries.selectedDates, warningAccepted: true });
    });
});
