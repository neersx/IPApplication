import { fakeAsync, flushMicrotasks, tick } from '@angular/core/testing';
import { FormBuilder } from '@angular/forms';
import { NotificationServiceMock } from 'ajs-upgraded-providers/notification-service.mock';
import { BsModalRefMock, ChangeDetectorRefMock, IpxNotificationServiceMock } from 'mocks';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { TimerModalServiceMock, TimerServiceMock } from '../time.recording-widget.mock';
import { TimerModalComponent } from './timer-modal.component';
import { TimerModalService } from './timer-modal.service';

describe('TimerWidgetComponent', () => {
  let c: TimerModalComponent;
  let cdRef: ChangeDetectorRefMock;
  let bsModalRef: BsModalRefMock;
  let destory: Observable<boolean>;
  let formBuilder: FormBuilder;
  let service: TimerServiceMock;
  let modalService: TimerModalServiceMock;
  let notificationService: NotificationServiceMock;
  let ipxNotificationService: IpxNotificationServiceMock;

  const deboundTime = 400;

  beforeEach(() => {
    cdRef = new ChangeDetectorRefMock();
    bsModalRef = new BsModalRefMock();
    destory = of(true).pipe(delay(10000));
    formBuilder = new FormBuilder();
    service = new TimerServiceMock();
    modalService = new TimerModalServiceMock();
    notificationService = new NotificationServiceMock();
    ipxNotificationService = new IpxNotificationServiceMock();

    c = new TimerModalComponent(bsModalRef as any, destory as any, formBuilder, service as any, modalService as any, notificationService as any, ipxNotificationService as any);
  });

  describe('init', () => {
    it('should create component', () => {
      expect(c).toBeTruthy();
    });

    it('should create the form group with blank data', () => {
      c.timerDetails = {};
      c.ngOnInit();

      expect(c.form).not.toBeNull();
      expect(c.activity).not.toBeNull();
      expect(c.narrativeNo).not.toBeNull();
      expect(c.narrativeText).not.toBeNull();
      expect(c.notes).not.toBeNull();

      expect(c.activity.value).toBeNull();
      expect(c.narrativeNo.value).toBeNull();
      expect(c.narrativeText.value).toBeNull();
      expect(c.notes.value).toBeNull();
    });

    it('should create the form group with passed data', () => {
      c.timerDetails = { start: new Date(2019, 1, 1, 10, 10), activity: 'Activity Name', activityKey: 'AA', narrativeNo: 10, narrativeTitle: 'N Title', narrativeText: 'N Text', notes: 'some notes' };
      c.ngOnInit();

      expect(c.form).not.toBeNull();
      expect(c.activity.value).toEqual({ key: 'AA', value: 'Activity Name' });
      expect(c.narrativeNo.value).toEqual({ key: 10, value: 'N Title', text: 'N Text' });
      expect(c.narrativeText.value).toEqual('N Text');
      expect(c.notes.value).toEqual('some notes');
    });
  });

  describe('value changes handling', () => {
    beforeEach(() => {
      c.timerDetails = { start: new Date(2019, 1, 1, 10, 10), caseId: { key: 90 }, nameId: { key: 9 }, activity: 'Activity Name', activityKey: 'AA', narrativeNo: 10, narrativeTitle: 'N Title', narrativeText: '', notes: 'some notes', staffNameId: 100 };
      c.ngOnInit();
    });
    it('on clearing activity, clear narrativeNo', fakeAsync(() => {
      c.activity.setValue(null);

      tick(deboundTime * 2);

      expect(c.narrativeNo.value).toBeNull();
      expect(c.narrativeText.value).toBeNull();
    }));

    it('on clearing activity, do not clear narrativeText', fakeAsync(() => {
      c.narrativeText.setValue('New narrative');
      tick(deboundTime);

      c.activity.setValue(null);
      tick(deboundTime);

      expect(c.narrativeText.value).not.toBeNull();
      expect(c.narrativeText.value).toEqual('New narrative');
    }));

    it('call to get narrative is done on setting activity', fakeAsync(() => {
      modalService.getDefaultNarrativeFromActivityVal = { key: 89, value: 'T', text: 'text' };

      c.activity.setValue({ key: 'K' });
      tick(deboundTime);
      expect(c.narrativeNo.disabled).toBeTruthy();

      expect(modalService.getDefaultNarrativeFromActivity).toHaveBeenCalled();
      expect(modalService.getDefaultNarrativeFromActivity.mock.calls[0][0]).toEqual('K');
      expect(modalService.getDefaultNarrativeFromActivity.mock.calls[0][1]).toEqual(c.timerDetails.caseId.key);
      expect(modalService.getDefaultNarrativeFromActivity.mock.calls[0][2]).toEqual(c.timerDetails.nameId.key);
      expect(modalService.getDefaultNarrativeFromActivity.mock.calls[0][3]).toEqual(c.timerDetails.staffNameId);

      tick(modalService.delayVal * 2);

      expect(c.narrativeNo.value).toEqual(modalService.getDefaultNarrativeFromActivityVal);
      expect(c.narrativeNo.enabled).toBeTruthy();
      expect(c.narrativeText.value).toEqual('text');
    }));

    it('narrativeText is defaulted from narrative', fakeAsync(() => {
      c.narrativeNo.setValue({ key: 'n', value: 'T', text: 'text' });
      tick(deboundTime);

      expect(c.narrativeText.value).toEqual('text');
    }));

    it('narrative is erased when narrative text is modified', fakeAsync(() => {
      c.narrativeText.setValue('new text value!');
      tick(deboundTime * 2);

      expect(c.narrativeNo.value).toBeNull();
    }));
  });

  describe('delete, save timer and cancel dialog', () => {
    let onCloseSpy;
    beforeEach(() => {
      c.timerDetails = { entryNo: 100, start: new Date(2019, 1, 1, 10, 10), caseId: { key: 90 }, nameId: { key: 9 }, activity: 'Activity Name', activityKey: 'AA', narrativeNo: 10, narrativeTitle: 'N Title', narrativeText: '', notes: 'some notes', staffNameId: 100 };
      c.ngOnInit();
      onCloseSpy = jest.spyOn(c.onClose$, 'emit');
    });
    it('cancel hides the timer widget', () => {
      c.cancel();
      expect(bsModalRef.hide).toHaveBeenCalled();
      expect(onCloseSpy).toHaveBeenCalled();
    });

    it('save data, calls to save the data and displays success', () => {
      c.notes.setValue('A brand new Timer!!!!');

      c.saveData();
      expect(service.saveTimer).toHaveBeenCalled();
      expect(service.saveTimer.mock.calls[0][0].entryNo).toBe(100);
      expect(service.saveTimer.mock.calls[0][0].start).toBe(c.timerDetails.start);
      expect(service.saveTimer.mock.calls[0][0].activity).toBe('AA');
      expect(service.saveTimer.mock.calls[0][0].narrativeText).toBe(null);
      expect(service.saveTimer.mock.calls[0][0].notes).toBe('A brand new Timer!!!!');
      expect(service.saveTimer.mock.calls[0][0].narrativeNo).toBe(10);
    });

    it('delete timer, confirms and calls to delete timer and displays success', fakeAsync(() => {
      ipxNotificationService.modalRef = { content: { confirmed$: of(true) } } as any;
      service.deleteTimerVal = true;
      c.deleteTimer();

      tick(service.delayVal);

      expect(ipxNotificationService.openDeleteConfirmModal).toHaveBeenCalledWith(expect.stringContaining('deleteTime'), null, false, null);
      expect(service.deleteTimer).toHaveBeenCalled();
      expect(service.deleteTimer.mock.calls[0][0]).toEqual(c.timerDetails);
      expect(notificationService.success).toHaveBeenCalled();
      expect(bsModalRef.hide).toHaveBeenCalled();

      expect(onCloseSpy).toHaveBeenCalled();
    }));

    it('delete timer is cancelled, if confirmation not provided', fakeAsync(() => {
      ipxNotificationService.modalRef = { content: { confirmed$: of(false).pipe(delay(2000)) } } as any;
      service.deleteTimerVal = true;
      c.deleteTimer();

      expect(ipxNotificationService.openDeleteConfirmModal).toHaveBeenCalled();
      tick(1000);
      expect(service.deleteTimer).not.toHaveBeenCalled();
    }));
  });

  describe('stop, reset timer', () => {
    let resetTimerSpy;
    let timerDetails;
    let onCloseSpy;

    beforeEach(() => {
      resetTimerSpy = jest.fn();
      timerDetails = { entryNo: 100, start: new Date(2019, 1, 1, 10, 10), caseId: { key: 90 }, nameId: { key: 9 }, activity: 'Activity Name', activityKey: 'AA', narrativeNo: 10, narrativeTitle: 'N Title', narrativeText: '', notes: 'some notes', staffNameId: 100 };
      c.timerDetails = { ...timerDetails };
      c.ngOnInit();
      c.timerClock = { time: 100, resetTimer: resetTimerSpy } as any;
      onCloseSpy = jest.spyOn(c.onClose$, 'emit');
    });

    it('stop timer and save', fakeAsync(() => {
      service.stopTimerVal = true;
      modalService.getDefaultNarrativeFromActivityVal = {};
      c.activity.setValue({ key: 'newAct' });
      tick(modalService.delayVal + 400);
      c.narrativeNo.setValue({ key: 111, value: 'newNarr', text: 'narrTitle' });
      tick(400);
      c.notes.setValue('New note');

      c.stopTimer();
      tick(service.delayVal);

      expect(service.stopTimer).toHaveBeenCalled();
      expect(service.stopTimer.mock.calls[0][0].entryNo).toBe(100);
      expect(service.stopTimer.mock.calls[0][0].start).toBe(c.timerDetails.start);
      expect(service.stopTimer.mock.calls[0][0].activity).toBe('newAct');
      expect(service.stopTimer.mock.calls[0][0].narrativeNo).toBe(111);
      expect(service.stopTimer.mock.calls[0][0].narrativeText).toBe('narrTitle');
      expect(service.stopTimer.mock.calls[0][0].notes).toBe('New note');
      expect(service.stopTimer.mock.calls[0][1]).toBe(100);
    }));

    it('displays success dialog after stopping timer', fakeAsync(() => {
      service.stopTimerVal = true;
      c.stopTimer();

      tick(service.delayVal);

      expect(notificationService.success).toHaveBeenCalled();
      expect(bsModalRef.hide).toHaveBeenCalled();
      expect(onCloseSpy).toHaveBeenCalled();
    }));

    it('reset timer and save', () => {
      c.notes.setValue('New note');

      c.resetTimer();
      expect(service.resetTimer).toHaveBeenCalled();
      expect(service.resetTimer.mock.calls[0][0]).toEqual(c.timerDetails);
    });

    it('displays success dialog after resetting the timer', fakeAsync(() => {
      service.resetTimerVal = { timeEntry: { entryNo: 100, start: '2019-02-01' } };

      c.resetTimer();
      tick(service.delayVal);

      const startDate = new Date(service.resetTimerVal.timeEntry.start);
      expect(service.resetTimer).toHaveBeenLastCalledWith(timerDetails);
      expect(notificationService.success).toHaveBeenCalled();
      expect(c.timerDetails.entryNo).toEqual(service.resetTimerVal.timeEntry.entryNo);
      expect(c.timerDetails.start).toEqual(startDate);
      expect(resetTimerSpy).toHaveBeenCalledWith(startDate);
    }));
  });
});