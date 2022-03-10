import { fakeAsync, tick } from '@angular/core/testing';
import { FormBuilder } from '@angular/forms';
import { ChangeDetectorRefMock, IpxNotificationServiceMock, NotificationServiceMock } from 'mocks';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { TimeCalculationServiceMock, TimeGapsServiceMock, TimeSettingsServiceMock } from '../time-recording.mock';
import { TimeGapsComponent } from './time-gaps.component';
import { WorkingHours } from './time-gaps.service';

describe('TimeGapsComponent', () => {
    let c: TimeGapsComponent;
    let gapsService: TimeGapsServiceMock;
    let cdRef: ChangeDetectorRefMock;
    let settingsService: TimeSettingsServiceMock;
    let notificationService: any;
    let formBuilder: FormBuilder;
    let timeCalcService: TimeCalculationServiceMock;
    let ipxNotificationService: IpxNotificationServiceMock;
    let ipxDestroy: any;
    let onAdditionCallBack: any;
    let timeRange: any;

    const dateWith = (selectedDate: Date, hours: number, minutes = 0, seconds = 0) => {
        const newDate = new Date(selectedDate);
        newDate.setHours(hours);
        newDate.setMinutes(minutes);
        newDate.setSeconds(seconds);

        return newDate;
    };

    beforeEach(() => {
        cdRef = new ChangeDetectorRefMock();
        gapsService = new TimeGapsServiceMock();
        settingsService = new TimeSettingsServiceMock();
        notificationService = new NotificationServiceMock();
        formBuilder = new FormBuilder();
        timeCalcService = new TimeCalculationServiceMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        ipxDestroy = of();

        c = new TimeGapsComponent(cdRef as any, gapsService as any, settingsService as any, notificationService, formBuilder, timeCalcService as any, ipxNotificationService as any, ipxDestroy);
        c._grid = new IpxKendoGridComponentMock() as any;
        onAdditionCallBack = jest.fn();
        gapsService.getWorkingHoursFromServer.mockImplementation(() => { return of(timeRange); });
    });

    describe('initialise correctly', () => {
        it('should create', () => {
            expect(c).toBeTruthy();
        });

        it('should set the default range', () => {
            c.viewData = { selectedDate: new Date(2019, 11, 2, 5, 7, 8) };
            timeRange = new WorkingHours(c.viewData.selectedDate, { fromSeconds: 8 * 2600, toSeconds: 18 * 3600 });
            c.ngOnInit();

            expect(c.timeRange.from.toDateString()).toEqual(new Date(2019, 11, 2, 8, 0, 0, 0).toDateString());
            expect(c.timeRange.to.toDateString()).toEqual(new Date(2019, 11, 2, 18, 0, 0, 0).toDateString());
        });

        it('should set grid options', () => {
            c.viewData = { selectedDate: new Date() };
            c.ngOnInit();

            expect(c.gridOptions).not.toBeNull();
            expect(c.gridOptions.columns[0].field).toBe('startTime');
            expect(c.gridOptions.columns[1].field).toBe('finishTime');
            expect(c.gridOptions.columns[2].field).toBe('durationInSeconds');
        });

        it('displays success notification once work hour preferences are saved', () => {
            c.viewData = { selectedDate: new Date() };
            gapsService.preferenceSaved$.mockReturnValue(of(true));
            c.ngOnInit();

            expect(notificationService.success).toHaveBeenCalledWith('accounting.time.gaps.prefSaved');
        });
    });

    describe('time range checks', () => {
        const currentDate = new Date(2019, 11, 2, 5, 7, 8);
        beforeEach(() => {
            c.viewData = { selectedDate: currentDate };
            timeRange = new WorkingHours(c.viewData.selectedDate, new WorkingHours(currentDate, null));
        });

        it('should call gapsService to save valid change to time range', () => {
            const selectedDate = new Date(2019, 11, 2);
            c.viewData = { selectedDate };

            const range = new WorkingHours(selectedDate, { fromSeconds: 11 * 3600, toSeconds: 15 * 3600 });

            c.ngOnInit();
            c.gridOptions._search = jest.fn();
            c.rangeChanged(range.from, range.to);

            expect(gapsService.saveWorkingHours).toHaveBeenCalled();
            expect(gapsService.saveWorkingHours.mock.calls[0][0].from).toEqual(range.from);
            expect(gapsService.saveWorkingHours.mock.calls[0][0].to).toEqual(range.to);
        });

        it('on value change, calls timeCalcService to determine partially entered value', fakeAsync(() => {
            const selectedDate = new Date(2019, 11, 2);
            c.viewData = { selectedDate };

            c.ngOnInit();
            tick(100);
            c.gridOptions._search = jest.fn();

            c.timeCalcService.parsePartiallyEnteredTime = jest.fn().mockReturnValueOnce(dateWith(selectedDate, 10)).mockReturnValueOnce(dateWith(selectedDate, 16));

            c.timeRangeFrom.setValue('10:00:00 AM');
            tick(100);
            expect(c.timeCalcService.parsePartiallyEnteredTime).toHaveBeenCalledWith('10:00:00 AM');

            c.timeRangeTo.setValue('11:00:00 AM');
            tick(100);
            expect(c.timeCalcService.parsePartiallyEnteredTime).toHaveBeenCalledWith('11:00:00 AM');

            expect(c.gridOptions._search).toHaveBeenCalled();
        }));

        it('sets error and clears grid if invalid time range', fakeAsync(() => {
            const selectedDate = new Date(2019, 11, 2);
            c.viewData = { selectedDate };

            c.ngOnInit();
            c.gridOptions._search = jest.fn();
            tick(100);

            c.timeCalcService.parsePartiallyEnteredTime = jest.fn().mockReturnValueOnce(dateWith(selectedDate, 16))
                .mockReturnValueOnce(dateWith(selectedDate, 1))
                .mockReturnValueOnce(dateWith(selectedDate, 16))
                .mockReturnValueOnce(dateWith(selectedDate, 1));

            c.timeRangeFrom.setValue('16:00:00 AM');
            c.timeRangeTo.setValue('1:00:00 AM');
            tick(100);

            expect(c._grid.clear).toHaveBeenCalled();
        }));
    });
    describe('data retrieval', () => {
        it('should make call to service to initialise data, with selected range', () => {
            const selectedDate = new Date(2019, 11, 2);
            const userNameId = 100;
            timeRange = { fromSeconds: 11 * 3600, toSeconds: 20 * 3600 };

            c.viewData = { userNameId, selectedDate };
            c.ngOnInit();
            c.gridOptions.read$(null);

            expect(gapsService.getGaps.mock.calls[0][0]).toEqual(100);
            expect(gapsService.getGaps.mock.calls[0][1]).toEqual(selectedDate);
            expect(gapsService.getGaps.mock.calls[0][2].from).not.toEqual(new Date(2019, 11, 2, 8));
            expect(gapsService.getGaps.mock.calls[0][2].to).not.toEqual(new Date(2019, 11, 2, 18));
        });

        describe('creating time entries from gaps', () => {
            it('is cancelled when add is disabled', () => {
                c.disableAdd = true;
                c.createItems();
                expect(gapsService.addEntries).not.toHaveBeenCalled();
            });
            it('calls the service to create time entries and handles the response', () => {
                c.viewData = { hasPendingChanges: false, onAddition: onAdditionCallBack };
                const disableAddSpy = jest.spyOn(c.disableAddChanges, 'next');
                c._grid.getRowSelectionParams = jest.fn().mockReturnValue({
                    allSelectedItems: [{ id: '1' }, { id: '2' }]
                });
                c.createItems();
                expect(disableAddSpy).toHaveBeenCalledWith(true);
                expect(gapsService.addEntries).toHaveBeenCalledWith([{ id: '1' }, { id: '2' }]);
                gapsService.addEntries().subscribe(() => {
                    expect(notificationService.success).toHaveBeenCalled();
                    expect(c._grid.search).toHaveBeenCalled();
                    expect(onAdditionCallBack).toHaveBeenCalled();
                });
            });
            it('displays confirmation dialog if there are pending changes and only proceeds if discarded', fakeAsync(() => {
                c.viewData = { hasPendingChanges: true, onAddition: onAdditionCallBack };
                const disableAddSpy = jest.spyOn(c.disableAddChanges, 'next');
                c._grid.getRowSelectionParams = jest.fn().mockReturnValue({
                    allSelectedItems: [{ id: '1' }, { id: '2' }]
                });
                ipxNotificationService.modalRef.content.confirmed$ = of(true).pipe(delay(100));
                gapsService.addEntries = jest.fn().mockReturnValue(of({ entries: [{ id: 1, entryNo: 100 }, { id: 5, entryNo: 67 }] }));
                c.createItems();
                tick(100);

                expect(disableAddSpy).toHaveBeenCalled();
                c.disableAddChanges.asObservable().subscribe((result) => {
                    expect(result).toBeTruthy();
                });
                expect(ipxNotificationService.openConfirmationModal).toHaveBeenCalled();
                expect(gapsService.addEntries).toHaveBeenCalled();
                expect(notificationService.success).toHaveBeenCalled();
                expect(c._grid.search).toHaveBeenCalled();
                expect(onAdditionCallBack).toHaveBeenCalledWith(100);
                expect(c.viewData.hasPendingChanges).toBeFalsy();
            }));
        });
        it('changing time range, initiates a call to service', () => {
            const selectedDate = new Date(2019, 11, 2, 0, 0, 0, 0);
            c.viewData = { selectedDate, userNameId: 100 };

            const range = new WorkingHours(selectedDate, { fromSeconds: 11 * 3600, toSeconds: 15 * 3600 });
            timeRange = new WorkingHours(selectedDate, { fromSeconds: 1 * 3600, toSeconds: 20 * 3600 });
            c.ngOnInit();

            c.gridOptions._search = jest.fn().mockImplementation(() => { c.gridOptions.read$(null); });
            c.rangeChanged(range.from, range.to);

            expect(gapsService.getGaps).toHaveBeenCalled();
            expect(gapsService.getGaps.mock.calls[0][0]).toBe(100);
            expect(gapsService.getGaps.mock.calls[0][1]).toEqual(selectedDate);
            expect(gapsService.getGaps.mock.calls[0][2].from).toEqual(range.from);
            expect(gapsService.getGaps.mock.calls[0][2].to).toEqual(range.to);
        });
    });
});
