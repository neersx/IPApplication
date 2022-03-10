import { fakeAsync, flushMicrotasks, tick } from '@angular/core/testing';
import { ChangeDetectorRefMock, NotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { WindowParentMessagingServiceMock } from 'mocks/window-parent-messaging.service.mock';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { TimerDetail, TimeRecordingWidgetComponent } from './time-recording-widget.component';
import { TimerServiceMock } from './time.recording-widget.mock';
import { TimerModalComponent } from './timer-modal/timer-modal.component';

describe('TimeRecordingWidgetComponent', () => {
    let messaging: any;
    let cdr: ChangeDetectorRefMock;
    let timerService: TimerServiceMock;
    let notificationService: NotificationServiceMock;
    let destroy$: any;
    let datepipe: any;
    let localeDate: any;
    let component: TimeRecordingWidgetComponent;
    let windowParentMessagingService: WindowParentMessagingServiceMock;
    let modalService: ModalServiceMock;

    beforeAll(() => {
        cdr = new ChangeDetectorRefMock();
        notificationService = new NotificationServiceMock();
        destroy$ = of();
        datepipe = { transform: jest.fn() };
        localeDate = { transform: jest.fn() };
        timerService = new TimerServiceMock();
        messaging = { message$: of() };
        windowParentMessagingService = new WindowParentMessagingServiceMock();
        modalService = new ModalServiceMock();
    });

    beforeEach(() => {
        component = new TimeRecordingWidgetComponent(cdr as any, timerService as any, notificationService as any, destroy$, datepipe, localeDate, messaging, windowParentMessagingService as any, modalService as any);
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    describe('checks on running timer', () => {
        beforeEach(() => {
            messaging = { subscribeToTimerMessages: jest.fn(), message$: of().pipe(delay(5)) };
        });
        it('stops timers running from previous day and displays notification', fakeAsync(() => {
            const stoppedTimer = { start: new Date(2010, 10, 1, 1, 2, 3) };
            timerService.checkCurrentRunningTimersVal = { stoppedTimer, runningTimer: null };
            component._timer = { resetTimer: jest.fn() } as any;

            localeDate.transform = jest.fn().mockReturnValue('1/10/2010');
            datepipe.transform = jest.fn().mockReturnValue('01:02:03');

            component.ngOnInit();
            tick(timerService.delayVal);

            expect(timerService.checkCurrentRunningTimers).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
            expect(notificationService.success.mock.calls[0][0]).toEqual('accounting.time.recording.prevTimerStopped');
            expect(notificationService.success.mock.calls[0][1].timerDate).toEqual('1/10/2010');
            expect(notificationService.success.mock.calls[0][1].startTime).toEqual('01:02:03');

            expect(localeDate.transform).toHaveBeenCalled();
            expect(localeDate.transform.mock.calls[0][0]).toEqual(stoppedTimer.start);
            expect(localeDate.transform.mock.calls[0][1]).toBeNull();

            expect(datepipe.transform).toHaveBeenCalled();
            expect(datepipe.transform.mock.calls[0][0]).toEqual(stoppedTimer.start);
            expect(datepipe.transform.mock.calls[0][1]).toEqual('HH:mm:ss');
        }));

        it('sets data for timer running for today', fakeAsync(() => {
            const runStartTime = new Date();
            runStartTime.setHours(10);
            runStartTime.setMinutes(30);
            const runningTimer = new TimerDetail({ start: runStartTime, entryNo: 10, name: 'ABCDK' });
            timerService.checkCurrentRunningTimersVal = { stoppedTimer: null, runningTimer };
            component._timer = { resetTimer: jest.fn() } as any;
            component.ngOnInit();
            tick(timerService.delayVal);

            expect(timerService.checkCurrentRunningTimers).toHaveBeenCalled();
            expect(component.data).toEqual(runningTimer);
            expect(component._isTimerRunning).toBeTruthy();
            expect(cdr.markForCheck).toHaveBeenCalled();
        }));
    });

    describe('when message is received', () => {
        const runStartTime = new Date();
        runStartTime.setMilliseconds(0);
        runStartTime.setSeconds(0);
        runStartTime.setMinutes(30);
        runStartTime.setHours(10);

        const runningTimer = new TimerDetail({ start: runStartTime, entryNo: 10, name: 'ABCDEFG' });
        beforeAll(() => {
            messaging = { subscribeToTimerMessages: jest.fn(), message$: of({ hasActiveTimer: true, basicDetails: runningTimer }).pipe(delay(5)) };
            timerService.checkCurrentRunningTimersVal = { stoppedTimer: null, runningTimer: null };
        });
        it('updates the timer data', fakeAsync(() => {
            component._timer = { resetTimer: jest.fn(), start: runningTimer.start, startTime: new Date(runningTimer.start).getTime() } as any;
            component.ngOnInit();
            tick(5);

            expect(component.data).toEqual(runningTimer);
            expect(component._isTimerRunning).toBeTruthy();
            expect(cdr.detectChanges).toHaveBeenCalled();
            expect(component._timer.resetTimer).not.toHaveBeenCalled();
        }));
        it('resets the timer where required', fakeAsync(() => {
            component._timer = { resetTimer: jest.fn(), start: new Date() } as any;
            component.ngOnInit();
            tick(5);

            expect(component.data).toEqual(runningTimer);
            expect(component._isTimerRunning).toBeTruthy();
            expect(cdr.detectChanges).toHaveBeenCalled();
            expect(component._timer.resetTimer).toHaveBeenCalledWith(runStartTime);
        }));
    });
    describe('when timer stopped in the background', () => {
        const runningTimer = new TimerDetail({ start: new Date(), entryNo: 10, name: 'ABCDEFG' });
        beforeAll(() => {
            messaging = { subscribeToTimerMessages: jest.fn(), message$: of({ hasActiveTimer: false, basicDetails: runningTimer }).pipe(delay(5)) };
            timerService.checkCurrentRunningTimersVal = { stoppedTimer: null, runningTimer };
        });
        it('displays message when timer is stopped in the background', fakeAsync(() => {
            component._timer = { resetTimer: jest.fn(), start: new Date() } as any;
            component.ngOnInit();
            tick(10);

            expect(notificationService.success).toHaveBeenCalled();
            expect(notificationService.success.mock.calls[0][0]).toBe('accounting.time.recording.prevTimerStopped');
            expect(component.data).toEqual(runningTimer);
            expect(component._isTimerRunning).toBeFalsy();
            expect(cdr.detectChanges).toHaveBeenCalled();
            expect(component._timer.resetTimer).not.toHaveBeenCalled();
        }));
    });
    describe('stopping the timer', () => {
        const runStartTime = new Date();
        runStartTime.setHours(1);
        runStartTime.setMinutes(30);
        const runningTimer = new TimerDetail({ start: runStartTime, entryNo: 10, name: 'ABCDE' });

        beforeEach(() => {
            timerService.checkCurrentRunningTimersVal = { stoppedTimer: null, runningTimer };
            timerService.stopTimerVal = true;
            component._timer = { resetTimer: jest.fn(), start: runningTimer.start, time: 90 } as any;
            component.data = runningTimer;
            component.ngOnInit();
        });
        it('calls the stop timer service', fakeAsync(() => {

            tick(timerService.delayVal);
            component.stopTimer();
            tick(timerService.delayVal);

            expect(timerService.stopTimer).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
        }));
    });

    describe('widget click', () => {
        const runStartTime = new Date();
        runStartTime.setMilliseconds(0);
        runStartTime.setSeconds(0);
        runStartTime.setHours(1);
        runStartTime.setMinutes(30);
        const runningTimer = new TimerDetail({ start: runStartTime, entryNo: 10, name: 'ABCDZ' });

        beforeAll(() => {
            messaging = { message$: of({}).pipe(delay(5)) };
        });

        beforeEach(() => {
            timerService.checkCurrentRunningTimersVal = { stoppedTimer: null, runningTimer };
            timerService.stopTimerVal = true;
            component.ngOnInit();
        });

        it('opens the timer modal', fakeAsync(() => {
            modalService.content = { onClose$: of() };
            component.widgetClick();
            expect(modalService.openModal).toHaveBeenCalled();
            expect(modalService.openModal.mock.calls[0][0]).toEqual(TimerModalComponent);
            expect(modalService.openModal.mock.calls[0][1].initialState.timerDetails).toEqual(runningTimer);

            tick(2000);
        }));

        describe('if hosted', () => {
            beforeEach(() => {
                component.isHosted = true;
            });
            it('sends messages if hosted', fakeAsync(() => {
                tick(timerService.delayVal);

                component.hostId = 'hostB';
                component.widgetClick();
                tick(2000);
                expect(windowParentMessagingService.postLifeCycleMessage).toHaveBeenCalled();
                expect(windowParentMessagingService.postLifeCycleMessage.mock.calls[0][0].action).toBe('onChange');
                expect(windowParentMessagingService.postLifeCycleMessage.mock.calls[0][0].target).toBe('hostB');
                expect(windowParentMessagingService.postLifeCycleMessage.mock.calls[0][0].payload.expand).toBeTruthy();
                expect(windowParentMessagingService.postLifeCycleMessage.mock.calls[0][0].payload.timerState).toBeTruthy();
            }));
            it('sends message to hosted component on hide', fakeAsync(() => {
                modalService.content = { onClose$: of({}) };
                component.hostId = 'hostA';

                component.widgetClick();
                windowParentMessagingService.postLifeCycleMessage.mockClear();

                tick(2000);

                expect(windowParentMessagingService.postLifeCycleMessage).toHaveBeenCalled();
                expect(windowParentMessagingService.postLifeCycleMessage.mock.calls[0][0].action).toBe('onChange');
                expect(windowParentMessagingService.postLifeCycleMessage.mock.calls[0][0].target).toBe('hostA');
                expect(windowParentMessagingService.postLifeCycleMessage.mock.calls[0][0].payload.expand).toBeFalsy();
                expect(windowParentMessagingService.postLifeCycleMessage.mock.calls[0][0].payload.timerState).toBeTruthy();
            }));
            it('sends message to hide timer if timers are stopped', fakeAsync(() => {
                windowParentMessagingService.postLifeCycleMessage.mockClear();

                component.hostId = 'hostC';
                modalService.content = { onClose$: of(false) };
                component.widgetClick();
                tick(500);
                expect(windowParentMessagingService.postLifeCycleMessage.mock.calls[0][0].action).toBe('onChange');
                expect(windowParentMessagingService.postLifeCycleMessage.mock.calls[0][0].target).toBe('hostC');
                expect(windowParentMessagingService.postLifeCycleMessage.mock.calls[0][0].payload.expand).toBeTruthy();
                expect(windowParentMessagingService.postLifeCycleMessage.mock.calls[0][0].payload.timerState).toBeTruthy();

                tick(500);
                expect(windowParentMessagingService.postLifeCycleMessage.mock.calls[1][0].action).toBe('onChange');
                expect(windowParentMessagingService.postLifeCycleMessage.mock.calls[1][0].target).toBe('hostC');
                expect(windowParentMessagingService.postLifeCycleMessage.mock.calls[1][0].payload.expand).toBeFalsy();
                expect(windowParentMessagingService.postLifeCycleMessage.mock.calls[1][0].payload.timerState).toBeFalsy();
            }));
        });

    });
});