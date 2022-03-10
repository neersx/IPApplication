import { fakeAsync, tick } from '@angular/core/testing';
import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { DateFunctions } from 'shared/utilities/date-functions';
import { TimerService } from './timer.service';

describe('Service: TimerWidget', () => {
    let http: HttpClientMock;
    let service: TimerService;

    beforeEach(() => {
        http = new HttpClientMock();
        service = new TimerService(http as any);
    });
    it('should create an instance', () => {
        expect(service).toBeTruthy();
    });

    describe('checkCurrentRunningTimers', () => {
        it('calls api to check running timers', () => {
            http.get = jest.fn().mockReturnValue(of({}));
            service.checkCurrentRunningTimers();
            expect(http.get).toHaveBeenCalledWith('api/accounting/timer/currentRunningTimer');
        });

        it('checkCurrentRunningTimers gets the time formats', () => {
            http.get = jest.fn().mockReturnValue(of({ timeFormat12Hours: true, displaySeconds: true }));
            service.checkCurrentRunningTimers();
            expect(service.timeFormat).toEqual('HH:mm:ss');
        });
    });

    it('startTimerFor calls the server api correctly', fakeAsync(() => {
        http.post = jest.fn().mockReturnValueOnce(of({ new: 'timer' }));

        service.startTimerFor(100);
        tick();
        expect(http.post.mock.calls[0][0]).toEqual('api/accounting/timer/start');
    }));

    it('saveTimer calls the server api correctly', fakeAsync(() => {
        const timerData = { some: 'data' };
        http.put = jest.fn().mockReturnValue(of({}));

        service.saveTimer(timerData);
        tick();
        expect(http.put).toHaveBeenCalled();
        expect(http.put.mock.calls[0][0]).toEqual('api/accounting/timer/save');
        expect(http.put.mock.calls[0][1].timeEntry).toEqual(timerData);
        expect(http.put.mock.calls[0][1].stopTimer).toBeFalsy();
    }));

    it('calls api to stop running timer', () => {
        const data = { entryNo: 10, start: new Date() };
        service.stopTimer(data, 100);
        expect(http.put).toHaveBeenCalled();
        expect(http.put.mock.calls[0][0]).toEqual('api/accounting/timer/stop');
        expect(http.put.mock.calls[0][1].start).toEqual(data.start);
        expect(http.put.mock.calls[0][1].entryNo).toEqual(10);

        const totalTime = new Date(1899, 0, 1);
        totalTime.setSeconds(100);
        expect(http.put.mock.calls[0][1].totalTime).toEqual(DateFunctions.toLocalDate(totalTime, false));
    });

    it('calls api to stop and save running timer', () => {
        const data = { entryNo: 10, start: new Date() };
        const newTotalTime = new Date(1899, 0, 1);
        newTotalTime.setSeconds(100);

        service.stopAndSaveTimer(data, 100);
        expect(http.put).toHaveBeenCalled();
        expect(http.put.mock.calls[0][0]).toEqual('api/accounting/timer/save');
        expect(http.put.mock.calls[0][1].timeEntry.entryNo).toEqual(10);
        expect(http.put.mock.calls[0][1].stopTimer).toBeTruthy();
        expect(http.put.mock.calls[0][1].timeEntry.totalTime).toEqual(DateFunctions.toLocalDate(newTotalTime, false));
    });

    it('resetTimer calls correct api to reset timer', () => {
        http.put.mockReturnValue(of());
        const startedTime = new Date();
        startedTime.setSeconds(100);
        service.resetTimer({ start: startedTime, entryNo: 10 });
        const localStartTime = DateFunctions.toLocalDate(startedTime, false);

        expect(http.put).toHaveBeenCalled();
        expect(http.put.mock.calls[0][0]).toEqual('api/accounting/timer/reset');
        expect(http.put.mock.calls[0][1].entryNo).toEqual(10);
        expect(http.put.mock.calls[0][1].start).not.toEqual(localStartTime);
    });

    it('deleteTimer calls the server api correctly', done => {
        const timerData = { some: 'data' };
        http.request = jest.fn().mockReturnValue(of({}));

        service.deleteTimer(timerData)
            .subscribe(() => {
                expect(http.request).toHaveBeenCalled();
                expect(http.request.mock.calls[0][0]).toEqual('delete');
                expect(http.request.mock.calls[0][1]).toEqual('api/accounting/time/delete');
                expect(http.request.mock.calls[0][2].body).toEqual(timerData);

                done();
            });
    });
});
