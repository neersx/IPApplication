import { fakeAsync, tick } from '@angular/core/testing';
import { WarningCheckerServiceMock } from 'accounting/warnings/warning.mock';
import { HttpClientMock, IpxNotificationServiceMock, NotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { of } from 'rxjs';
import { take } from 'rxjs/operators';
import * as _ from 'underscore';
import { TimeRecordingTimerGlobalService } from './time-recording-timer-global.service';
import { TimerServiceMock } from './time.recording-widget.mock';
import { TimerModalComponent } from './timer-modal/timer-modal.component';

describe('Service: TimeRecordingTimerGlobalService', () => {
  let httpClientSpy: any;
  let notificationService: NotificationServiceMock;
  let modalService: ModalServiceMock;
  let warningChecker: WarningCheckerServiceMock;
  let datePipe: any;
  let service: TimeRecordingTimerGlobalService;
  let timerService: TimerServiceMock;
  let ipxNotificationService: IpxNotificationServiceMock;

  beforeEach(() => {
    httpClientSpy = new HttpClientMock();
    notificationService = new NotificationServiceMock();
    modalService = new ModalServiceMock();
    warningChecker = new WarningCheckerServiceMock();
    datePipe = { transform: jest.fn() };
    timerService = new TimerServiceMock();
    ipxNotificationService = new IpxNotificationServiceMock();

    service = new TimeRecordingTimerGlobalService(notificationService as any, modalService as any, warningChecker as any, datePipe, timerService as any, ipxNotificationService as any);
  });
  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  describe('startTimerForCase', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    it('returns if valid casekey not provided', () => {
      service.timerDetailsClosed$.pipe(take(1)).subscribe((res) => expect(res).toBeFalsy());
      service.startTimerForCase(null);
      expect(warningChecker.performCaseWarningsCheck).not.toHaveBeenCalled();

      service.timerDetailsClosed$.pipe(take(1)).subscribe((res) => expect(res).toBeFalsy());
      service.startTimerForCase(undefined);
      expect(warningChecker.performCaseWarningsCheck).not.toHaveBeenCalled();

      service.startTimerForCase(0);
      expect(warningChecker.performCaseWarningsCheck).toHaveBeenCalled();
      expect(warningChecker.performCaseWarningsCheck.mock.calls[0][0]).toEqual(0);

      service.startTimerForCase(100);
      expect(warningChecker.performCaseWarningsCheck).toHaveBeenCalledTimes(2);
      expect(warningChecker.performCaseWarningsCheck.mock.calls[1][0]).toEqual(100);
    });

    it('timer is not started if warnings blocked are not proceeded', () => {
      warningChecker.performCaseWarningsCheckResult = of(false);
      service.startTimerForCase(100);

      expect(httpClientSpy.get).not.toHaveBeenCalledWith('api/accounting/timer/start');
    });

    it('starts the timer and success notification is displayed along with stopped timer details', fakeAsync(() => {
      warningChecker.performCaseWarningsCheckResult = of(true);
      timerService.startTimerForVal = { stoppedTimer: { start: 'abcd' } };

      const timeValue = '11:11:11';
      datePipe.transform = jest.fn().mockReturnValueOnce(timeValue);

      service.startTimerForCase(100);
      tick(timerService.delayVal + 500);

      expect(timerService.startTimerFor).toHaveBeenCalledWith(100);
      expect(notificationService.success).toHaveBeenCalled();
      expect(notificationService.success.mock.calls[0][0]).toEqual('accounting.time.recording.timerStoppedAndNewStarted');
      expect(notificationService.success.mock.calls[0][1].startTime).toEqual(timeValue);

      expect(datePipe.transform).toHaveBeenCalled();
      expect(datePipe.transform.mock.calls[0][0]).toEqual('abcd');
      expect(datePipe.transform.mock.calls[0][1]).toEqual('HH:mm:ss');
    }));

    it('displays the timer basic details dialog after starting the timer', fakeAsync(() => {
      const startedTimer = { new: 'timer' };
      timerService.startTimerForVal = { startedTimer };
      warningChecker.performCaseWarningsCheckResult = of(true);

      service.startTimerForCase(100);
      tick(timerService.delayVal + 500);

      expect(notificationService.success).toHaveBeenCalled();
      expect(modalService.openModal).toHaveBeenCalled();
      expect(modalService.openModal.mock.calls[0][0]).toEqual(TimerModalComponent);
      expect(modalService.openModal.mock.calls[0][1].initialState.timerDetails).toEqual(startedTimer);
    }));
  });
});