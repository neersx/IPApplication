import { fakeAsync, tick } from '@angular/core/testing';
import { FormBuilder } from '@angular/forms';
import { of } from 'rxjs';
import { TimeEntryEx } from './time-recording-model';
import { TimeCalculationServiceMock, TimeRecordingServiceMock, TimeSettingsServiceMock } from './time-recording.mock';
import { TimesheetFormsService } from './timesheet-forms.service';

describe('Service: TimesheetFormsService', () => {
  let timeCalcService: any;
  let timeRecording: any;
  let formBuilder: any;
  let settingsService: any;
  let service: TimesheetFormsService;

  beforeEach(() => {
    timeCalcService = new TimeCalculationServiceMock();
    timeRecording = new TimeRecordingServiceMock();
    formBuilder = new FormBuilder();
    settingsService = new TimeSettingsServiceMock();
    service = new TimesheetFormsService(timeCalcService, timeRecording, formBuilder, settingsService);
  });

  describe('initialisation', () => {
    it('should create an instance', () => {
      expect(service).toBeTruthy();
    });

    it('should create form with required controls and initial values, for new entry', () => {
      service.createFormGroup(new TimeEntryEx());

      expect(service.formGroup).not.toBeNull();
      expect(service.start).not.toBeNull();
      expect(service.finish).not.toBeNull();
      expect(service.elapsedTime).not.toBeNull();
      expect(service.totalUnits).not.toBeNull();
      expect(service.name).not.toBeNull();
      expect(service.caseReference).not.toBeNull();
      expect(service.activity).not.toBeNull();
      expect(service.narrativeText).not.toBeNull();
      expect(service.notes).not.toBeNull();
    });

    it('should create form with required controls and initial values, for edit entry', () => {
      const elapsedTime = new Date(1899, 0, 1, 1, 0, 0);
      timeCalcService.calculateElapsed = jest.fn().mockReturnValue(elapsedTime);

      const entry = new TimeEntryEx({
        start: new Date(2010, 11, 5, 1, 0, 0),
        finish: new Date(2010, 11, 5, 2, 0, 0),
        elapsedTimeInSeconds: 1000,
        totalUnits: 100,
        narrativeText: 'EFGH',
        notes: 'ABCD'
      });
      const result = service.createFormGroup(entry);
      expect(result).not.toBeNull();

      expect(service.start.value).toEqual(entry.start);
      expect(service.finish.value).toEqual(entry.finish);
      expect(service.elapsedTime.value).toEqual(elapsedTime);
      expect(service.totalUnits.value).toEqual(entry.totalUnits);
      expect(service.narrativeText.value).toEqual(entry.narrativeText);
      expect(service.notes.value).toEqual(entry.notes);
    });

    it('should disable name and case while editing debtor only posted entry', () => {
      const elapsedTime = new Date(1899, 0, 1, 1, 0, 0);
      timeCalcService.calculateElapsed = jest.fn().mockReturnValue(elapsedTime);

      const entry = new TimeEntryEx({
        start: new Date(2010, 11, 5, 1, 0, 0),
        finish: new Date(2010, 11, 5, 2, 0, 0),
        elapsedTimeInSeconds: 1000,
        isPosted: true,
        nameKey: 100,
        caseKey: null
      });
      const result = service.createFormGroup(entry);
      expect(result).not.toBeNull();

      expect(service.caseReference.disabled).toBeTruthy();
      expect(service.name.disabled).toBeTruthy();
    });

    it('should disable name while editing posted entry with case', () => {
      const elapsedTime = new Date(1899, 0, 1, 1, 0, 0);
      timeCalcService.calculateElapsed = jest.fn().mockReturnValue(elapsedTime);

      const entry = new TimeEntryEx({
        start: new Date(2010, 11, 5, 1, 0, 0),
        finish: new Date(2010, 11, 5, 2, 0, 0),
        elapsedTimeInSeconds: 1000,
        isPosted: true,
        nameKey: 100,
        caseKey: 1
      });
      const result = service.createFormGroup(entry);
      expect(result).not.toBeNull();

      expect(service.caseReference.disabled).toBeFalsy();
      expect(service.name.disabled).toBeTruthy();
    });

    it('should create form with required controls for new timer entry', () => {
      const input = new TimeEntryEx();
      input.isTimer = true;

      service.createFormGroup(input);

      expect(service.formGroup).not.toBeNull();
      expect(service.start).toBeNull();
      expect(service.finish).toBeNull();
      expect(service.elapsedTime).toBeNull();
      expect(service.totalUnits).toBeNull();
      expect(service.name).not.toBeNull();
      expect(service.caseReference).not.toBeNull();
      expect(service.activity).not.toBeNull();
      expect(service.narrativeText).not.toBeNull();
      expect(service.notes).not.toBeNull();
    });

    it('should load the form data and disable relevant fields on continue', () => {
      const input = new TimeEntryEx();
      const parentEntry = { narrativeNo: { key: 1 }, caseReference: { key: 10, code: '1234/A' }, nameKey: 9, name: 'ABCD' , activity: { key: 'Active1', value: 'someactivitiy' }, notes: 'blah blha', narrativeText: 'default this NOW!' };
      service.continue(parentEntry as unknown as TimeEntryEx, input);
      service.createFormGroup(parentEntry as unknown as TimeEntryEx);

      expect(service.narrativeNo.value.key.key).toEqual(parentEntry.narrativeNo.key);
      expect(service.caseReference.value.code.key).toEqual(parentEntry.caseReference.key);
      expect(service.caseReference.value.code.code).toEqual(parentEntry.caseReference.code);
      expect(service.name.value.key).toEqual(parentEntry.nameKey);
      expect(service.name.value.displayName).toEqual(parentEntry.name);
      expect(service.activity.value.value.key).toEqual(parentEntry.activity.key);
      expect(service.activity.value.value.value).toEqual(parentEntry.activity.value);
      expect(service.notes.value).toEqual(parentEntry.notes);

      expect(service.caseReference.disabled).toBeTruthy();
      expect(service.name.disabled).toBeTruthy();
      expect(service.activity.disabled).toBeTruthy();
      expect(service.narrativeNo.disabled).toBeFalsy();
      expect(service.narrativeText.disabled).toBeFalsy();
      expect(service.notes.disabled).toBeFalsy();
    });
  });

  describe('Form validation', () => {
    const entry = new TimeEntryEx({
      start: new Date(2010, 11, 5, 5, 0, 0),
      finish: new Date(2010, 11, 5, 7, 0, 0),
      elapsedTimeInSeconds: 1000,
      totalUnits: 100,
      narrativeText: 'EFGH',
      notes: 'ABCD'
    });

    it('sets error is start time greater than finish', fakeAsync(() => {
      const newElapsed = new Date(1899, 0, 1, 2, 0, 0);
      timeCalcService.calculateElapsed = jest.fn().mockReturnValue(newElapsed);

      service.createFormGroup(entry);
      tick(service.debounceDelay);

      const newFinishTime = new Date(2010, 11, 5, 1, 0, 0);
      service.finish.setValue(newFinishTime);
      tick(service.debounceDelay);

      expect(service.start.value).toEqual(entry.start);
      expect(service.finish.value).toEqual(newFinishTime);
      expect(service.elapsedTime.value).toEqual(newElapsed);

      expect(service.finish.errors.errorMessage).toEqual('accounting.time.recording.validationMsgs.finishShouldBeLaterThanStart');
      expect(service.formGroup.invalid).toBe(true);
    }));

    it('sets error if finish time would go beyond the day selected', fakeAsync(() => {
      const elapsed = new Date(1899, 0, 1, 2, 0, 0);
      timeCalcService.calculateElapsed = jest.fn().mockReturnValue(elapsed);

      service.createFormGroup(entry);
      tick(service.debounceDelay);

      const newElapsedTime = new Date(2010, 11, 5, 22, 0, 0);
      service.elapsedTime.setValue(newElapsedTime);
      tick(service.debounceDelay);

      expect(service.start.value).toEqual(entry.start);
      expect(service.finish.value).toEqual(entry.finish);
      expect(service.elapsedTime.value).toEqual(newElapsedTime);

      expect(service.elapsedTime.errors.errorMessage).toEqual('accounting.time.recording.validationMsgs.finishNotSameDayAsStart');
      expect(service.formGroup.invalid).toBe(true);
    }));

    it('sets error if units selected are more than max units', fakeAsync(() => {
      settingsService.unitsPerHour = 1;
      const elapsed = new Date(1899, 0, 1, 2, 0, 0);
      timeCalcService.calculateElapsed = jest.fn().mockReturnValue(elapsed);

      service.createFormGroup(entry);
      tick(service.debounceDelay);

      service.totalUnits.setValue(25);
      tick(service.debounceDelay);
      expect(service.totalUnits.errors['timeRecording.maxUnitsExceeded']).toEqual(true);
      expect(service.formGroup.invalid).toBe(true);
    }));
  });

  describe('Form value changes', () => {
    const entry = {
      start: new Date(2010, 11, 5, 5, 0, 0),
      finish: new Date(2010, 11, 5, 7, 0, 0),
      elapsedTimeInSeconds: 7200,
      totalUnits: 100,
      notes: 'ABCD',
      narrativeText: null,
      narrativeNo: null,
      activity: null,
      activityKey: null,
      caseReference: null
    };

    it('should call handler when start field is changed', fakeAsync(() => {
      service.createFormGroup(entry as TimeEntryEx);
      tick(service.debounceDelay);

      const newFinish = new Date(2010, 11, 5, 14, 0, 0);
      const newElapsed = new Date(1899, 0, 1, 5, 0, 0);
      timeCalcService.calculateFinished = jest.fn().mockReturnValue(newFinish);
      timeCalcService.calculateElapsed = jest.fn().mockReturnValueOnce(new Date(1899, 0, 1, 2, 0, 0)).mockReturnValue(newElapsed);

      const startTime = new Date(2010, 11, 5, 1, 0, 0);
      service.start.setValue(startTime);
      tick(service.debounceDelay);

      expect(service.start.value).toEqual(startTime);
      expect(service.finish.value).toEqual(newFinish);
      expect(service.elapsedTime.value).toEqual(newElapsed);
    }));

    it('should call handler when finish field is changed', fakeAsync(() => {
      entry.elapsedTimeInSeconds = null;
      service.createFormGroup(entry as TimeEntryEx);
      tick(service.debounceDelay);
      const newElapsed = new Date(1899, 0, 1, 5, 0, 0);
      timeCalcService.calculateElapsed = jest.fn().mockReturnValueOnce(new Date(1899, 0, 1, 2, 0, 0)).mockReturnValueOnce(newElapsed);
      timeCalcService.calculateFinished = jest.fn().mockReturnValueOnce(new Date(2010, 11, 5, 10, 0, 0));

      const endTime = new Date(2010, 11, 5, 10, 0, 0);
      service.finish.setValue(endTime);
      tick(service.debounceDelay);

      expect(service.start.value).toEqual(entry.start);
      expect(service.finish.value).toEqual(endTime);
    }));

    it('should call handler when duration field is changed', fakeAsync(() => {
      service.createFormGroup(entry as TimeEntryEx);
      tick(service.debounceDelay);

      const newFinish = new Date(1899, 0, 1, 6, 0, 0);
      timeCalcService.calculateElapsed = jest.fn().mockReturnValueOnce(new Date(1899, 0, 1, 2, 0, 0));
      timeCalcService.calculateFinished = jest.fn().mockReturnValue(newFinish);

      const elapsedTime = new Date(1899, 0, 1, 1, 0, 0);
      service.elapsedTime.setValue(elapsedTime);
      tick(service.debounceDelay);

      expect(service.start.value).toEqual(entry.start);
      expect(service.finish.value).toEqual(newFinish);
      expect(service.elapsedTime.value).toEqual(elapsedTime);
    }));

    it('should call not fetch narratives if already filled', fakeAsync(() => {
      entry.elapsedTimeInSeconds = null;
      entry.narrativeText = 'ABCD';
      entry.finish = null;
      service.createFormGroup(entry as TimeEntryEx);

      expect(service.narrativeText.value).toEqual(entry.narrativeText);

      service.activity.setValue('abcXYZ');
      tick(service.debounceDelay);

      expect(service.start.value).toEqual(entry.start);
      expect(service.finish.value).toBeNull();
      expect(service.elapsedTime.value).toBeNull();

      expect(service.activity.value).toEqual('abcXYZ');
      expect(service.narrativeNo.value).not.toBeNull();
    }));

    describe('changing the activity', () => {
      it('should call handler when activity field is changed', fakeAsync(() => {
        service.createFormGroup(entry as TimeEntryEx);

        const activity = { key: 'abcXYZ' };
        service.activity.setValue(activity);
        service.caseReference.setValue(null);
        service.narrativeNo.setValue({key: 332, value: 'narrative is set'});
        service.name.setValue(null);
        tick(service.debounceDelay);

        expect(timeRecording.getDefaultNarrativeFromActivity).toHaveBeenCalledWith(activity.key, null, null, null);
        expect(service.activity.value).toEqual(activity);
        expect(service.narrativeNo.value).toEqual({ narrative: 'a' });
      }));
      it('should call handler with caseKey when activity field is changed', fakeAsync(() => {
        service.createFormGroup(entry as TimeEntryEx);
        const activity = { key: 'abcXYZ' };
        service.activity.setValue(activity);
        service.caseReference.setValue({ key: 1001 });
        service.name.setValue(null);
        service.narrativeNo.setValue({key: 332, value: 'narrative is set'});
        tick(service.debounceDelay);

        expect(timeRecording.getDefaultNarrativeFromActivity).toHaveBeenCalledWith(activity.key, 1001, null, null);
        expect(service.activity.value).toEqual(activity);
        expect(service.narrativeNo.value).toEqual({ narrative: 'a' });
      }));
      it('should call handler with debtorKey when activity field is changed', fakeAsync(() => {
        service.createFormGroup(entry as TimeEntryEx);

        const activity = { key: 'abcXYZ' };
        service.activity.setValue(activity);
        service.caseReference.setValue(null);
        service.name.setValue({ key: -1001 });
        service.narrativeNo.setValue({key: 332, value: 'narrative is set'});
        tick(service.debounceDelay);

        expect(timeRecording.getDefaultNarrativeFromActivity).toHaveBeenCalledWith(activity.key, null, -1001, null);
        expect(service.activity.value).toEqual(activity);
        expect(service.narrativeNo.value).toEqual({ narrative: 'a' });
      }));
    });
  });

  describe('Data fetching', () => {
    const entry = {
      start: new Date(2010, 11, 5, 5, 0, 0),
      finish: new Date(2010, 11, 5, 8, 0, 0),
      elapsedTimeInSeconds: 1000,
      totalUnits: 100,
      narrativeText: 'EFGH',
      notes: 'ABCD'
    };

    beforeEach(() => {
      service.createFormGroup(entry as TimeEntryEx);
    });

      it('should return selected name', fakeAsync(() => {
          const name = 'ABCD';
          service.name.setValue(name);

          expect(service.getSelectedName()).toBe(name);
      }));

    it('should return selected case', fakeAsync(() => {
      const caseRef = 'ABCD';
      service.caseReference.setValue(caseRef);
      expect(service.getSelectedCaseRef()).toBe(caseRef);
    }));

    it('should return entered data', fakeAsync(() => {
      const name = { key: 'ABCD' };
      const caseRef = { key: 'XYZ' };
      service.name.setValue(name);
        service.caseReference.setValue(null);

      let result = service.getDataToSave();

      expect(result.start).toEqual(entry.start);
      expect(result.finish).toEqual(entry.finish);
      expect(result.nameKey).toEqual(name.key);
      expect(result.caseKey).toBeNull();
      expect(result.narrativeText).toEqual(entry.narrativeText);
      expect(result.notes).toEqual(entry.notes);

        service.caseReference.setValue(caseRef);
        result = service.getDataToSave();

        expect(result.start).toEqual(entry.start);
        expect(result.finish).toEqual(entry.finish);
        expect(result.nameKey).toBeNull();
        expect(result.caseKey).toEqual(caseRef.key);
        expect(result.narrativeText).toEqual(entry.narrativeText);
        expect(result.notes).toEqual(entry.notes);
    }));

      it('should return entered data for timer entry', () => {
          const input = { ...entry, isTimer: true };
          service.createFormGroup(input as TimeEntryEx);
          const name = { key: 'ABCD' };
          const caseRef = { key: 'XYZ' };
          service.name.setValue(name);
          service.caseReference.setValue(null);

          let result = service.getDataToSave();

          expect(result.start).toBeNull();
          expect(result.finish).toBeNull();
          expect(result.totalTime).toBeNull();
          expect(result.elapsedTimeInSeconds).toBeNull();
          expect(result.totalUnits).toBeNull();
          expect(result.nameKey).toEqual(name.key);
          expect(result.caseKey).toBeNull();
          expect(result.narrativeText).toEqual(entry.narrativeText);
          expect(result.notes).toEqual(entry.notes);

          service.caseReference.setValue(caseRef);
          result = service.getDataToSave();

          expect(result.start).toBeNull();
          expect(result.finish).toBeNull();
          expect(result.totalTime).toBeNull();
          expect(result.elapsedTimeInSeconds).toBeNull();
          expect(result.totalUnits).toBeNull();
          expect(result.nameKey).toBeNull();
          expect(result.caseKey).toEqual(caseRef.key);
          expect(result.narrativeText).toEqual(entry.narrativeText);
          expect(result.notes).toEqual(entry.notes);
      });
  });

  describe('Clear Time', () => {
    const init = (): void => {
      service.createFormGroup(null);
      settingsService.timeEmptyForNewEntries = false;
      service.formGroup.reset = jest.fn();
      service.finish.reset = jest.fn();
      service.elapsedTime.reset = jest.fn();
    };

    it('should reset the form back to original when clicked on clear', () => {
      init();
      let nextDate: Date = new Date();
      nextDate = new Date(nextDate.setDate(nextDate.getDate() + 1));
      service.start.setValue(nextDate);
      timeCalcService.selectedDate = new Date();
      service.clearTime();
      expect(timeCalcService.initializeStartTime).toHaveBeenCalled();
      expect(service.formGroup.reset).toHaveBeenCalled();
    });
    it('should only reset time fields for continued entries', () => {
      init();
      service.isContinuedEntryMode = true;
      let nextDate: Date = new Date();
      nextDate = new Date(nextDate.setDate(nextDate.getDate() + 1));
      service.start.setValue(nextDate);
      timeCalcService.selectedDate = new Date();
      service.clearTime();
      expect(timeCalcService.initializeStartTime).toHaveBeenCalled();
      expect(service.formGroup.reset).not.toHaveBeenCalled();
      expect(service.finish.reset).toHaveBeenCalled();
      expect(service.elapsedTime.reset).toHaveBeenCalled();
    });

    it('should reset start time, if start control is present', () => {
      const input: TimeEntryEx = { isTimer: true } as any;
      service.createFormGroup(input);
      service.clearTime();

      expect(timeCalcService.initializeStartTime).not.toHaveBeenCalled();
    });
  });

  describe('Units Changed', () => {
    beforeEach(() => {
      service.createFormGroup(null);
    });
    it('should leave the duration as is when the units entered is not a whole number or has decimals', fakeAsync(() => {
      service._onUnitsChanged();
      service.elapsedTime.setValue(1);
      tick(service.debounceDelay);
      expect(service.elapsedTime.value).not.toBeNull();
    }));

    it('should set the start & finish to null when the units is changed, and calls the service', fakeAsync(() => {
      timeCalcService.calcDurationFromUnits = jest.fn();
      service._onUnitsChanged();
      const value = 2;
      service.start.setValue(1);
      service.finish.setValue(1);
      timeCalcService.calcDurationFromUnits = jest.fn();
      service.totalUnits.setValue(value);
      tick(service.debounceDelay);
      expect(service.start.value).toBeNull();
      expect(service.finish.value).toBeNull();
      expect(timeCalcService.calcDurationFromUnits).toHaveBeenCalledWith(value, null);
    }));
    it('should consider secondsCarriedForward where available', fakeAsync(() => {
      const timeEntry: TimeEntryEx = {
        secondsCarriedForward: 600,
        start: new Date(),
        finish: new Date(),
        elapsedTimeInSeconds: 0,
        totalTime: new Date(),
        totalUnits: 0,
        caseReference: '',
        activity: '',
        chargeOutRate: 0,
        localValue: 0,
        localDiscount: 0,
        foreignValue: 0,
        foreignDiscount: 0,
        foreignCurrency: 'xyz',
        narrativeText: '',
        notes: '',
        accumulatedTimeInSeconds: 0,
        hasDifferentCurrencies: false,
        hasDifferentChargeRates: false,
        makeServerReady: undefined,
        clearOutTimeSpecifications: undefined
      };
      timeCalcService.calcDurationFromUnits = jest.fn();
      service.originalDetails = timeEntry;
      service._onUnitsChanged();
      const value = 2;
      service.start.setValue(1);
      service.finish.setValue(1);
      service.totalUnits.setValue(value);
      tick(service.debounceDelay);
      expect(service.start.value).toBeNull();
      expect(service.finish.value).toBeNull();
      expect(timeCalcService.calcDurationFromUnits).toHaveBeenCalledWith(value, 600);
    }));
  });

  describe('time valuation', () => {
    beforeEach(() => {
      settingsService.valueTimeOnEntry = true;
    });

    const init = (): void => {
      service.createFormGroup(new TimeEntryEx());
      service.formGroup.markAsTouched();
      tick(100);
    };

    it('should perform time valuation if elapsed time changes, due to start change', fakeAsync(() => {
      init();

      service.start.setValue(new Date(2019));
      tick(100);

      expect(timeRecording.evaluateTime).toHaveBeenCalled();
    }));

    it('should perform time valuation if elapsed time changes, due to finish change', fakeAsync(() => {
      init();
      service.finish.setValue(new Date(2020));
      tick(service.debounceDelay);

      expect(timeRecording.evaluateTime).toHaveBeenCalled();
    }));

    it('should perform time valuation if elapsed time changes', fakeAsync(() => {
      init();
      const elapsedTimeVal = new Date(1899, 0, 1, 0, 0, 1000);
      service.elapsedTime.setValue(elapsedTimeVal);
      tick(service.debounceDelay);

      expect(timeRecording.evaluateTime).toHaveBeenCalled();
      expect(timeRecording.evaluateTime.mock.calls[0][2].elapsedTimeInSeconds).toEqual(elapsedTimeVal);
    }));

    it('should not pass elapased time value, if start, finish or duration has error set', fakeAsync(() => {
      init();
      service.start.setValue(new Date());
      service.start.setErrors({ someError: 'It is wrong!' });

      service.elapsedTime.setValue(new Date(2021));
      tick(service.debounceDelay);

      expect(timeRecording.evaluateTime).toHaveBeenCalled();
      expect(timeRecording.evaluateTime.mock.calls[0][2].elapsedTimeInSeconds).toBeNull();
    }));

    it('should make a call to evaluate time on activity change', fakeAsync(() => {
      init();
      service.activity.setValue('abcXYZ');
      tick(service.debounceDelay);

      expect(timeRecording.evaluateTime).toHaveBeenCalled();
    }));

    it('should not make a call to evaluate time if setting valueTimeOnEntry is off ', fakeAsync(() => {
      settingsService.valueTimeOnEntry = false;
      service.createFormGroup(new TimeEntryEx());
      service.formGroup.markAsTouched();

      service.activity.setValue('abcXYZ');
      tick(service.debounceDelay);

      expect(timeRecording.evaluateTime).not.toHaveBeenCalled();
    }));

    it('should not make a call to evaluate time if timer entry', fakeAsync(() => {
      const input = new TimeEntryEx();
      input.isTimer = true;
      service.createFormGroup(input);
      settingsService.valueTimeOnEntry = true;
      service.activity.setValue('abcXYZ');
      tick(service.debounceDelay);

      expect(timeRecording.evaluateTime).not.toHaveBeenCalled();
    }));

    it('should set the staleFinancials flag, if valueTimeOnEntry is false', fakeAsync(() => {
      init();
      expect(service.staleFinancials).toBeFalsy();
      settingsService.valueTimeOnEntry = false;
      service.formGroup.markAsDirty();
      service.activity.setValue('abcXYZ');
      tick(service.debounceDelay);

      expect(service.staleFinancials).toBeTruthy();
    }));
  });
  describe('Default Narrative', () => {
    beforeEach(() => {
      service.evaluateTime = jest.fn();
    });
    it('should return if narrative text was modified or narrative was defaulted by case', fakeAsync(() => {
      timeRecording.rowSelected.next = jest.fn();
      const defaultActivitySpy = timeRecording.getDefaultNarrativeFromActivity = jest.fn();
      service.createFormGroup(null);
      service.narrativeText.setValue('aa');
      service.activity.setValue({ key: 457 });
      tick(service.debounceDelay);
      expect(defaultActivitySpy).not.toHaveBeenCalled();
    }));
    it('should call defaultActivitySpy if narrative text was not modified or narrative was not defaulted by case', fakeAsync(() => {
      timeRecording.rowSelected.next = jest.fn();
      service.createFormGroup(null);
      service.activity.setValue({ key: 45 });
      service.activity.setValue({ key: 457 });
      tick(service.debounceDelay);
      service.activity.valueChanges.subscribe(() => {
        expect(service.evaluateTime).toHaveBeenCalled();
        expect(timeRecording.getDefaultNarrativeFromActivity).toHaveBeenCalledWith(457, null);
      });
    }));
    it('should set the correct narrative value', fakeAsync(() => {
      timeRecording.rowSelected.next = jest.fn();
      const response = 'aaa';
      const defaultNarrativeSpy = timeRecording.getDefaultNarrativeFromActivity = jest.fn().mockReturnValue(of(response));
      service.createFormGroup(null);
      service.activity.setValue({ key: 45 });
      service.activity.setValue({ key: 457 });
      tick(service.debounceDelay);
      service.activity.valueChanges.subscribe(() => {
        expect(service.evaluateTime).toHaveBeenCalled();
        expect(defaultNarrativeSpy).toHaveBeenCalledWith(457, null);
        expect(service.narrativeNo.setValue).toHaveBeenCalledWith('aaa');
      });
    }));
    it('should clear the non null narrative value if activity is cleared', fakeAsync(() => {
      timeRecording.rowSelected.next = jest.fn();
      service.createFormGroup(null);
      service.narrativeNo.setValue('aa');
      service.activity.setValue({ key: 45 });
      service.activity.setValue(null);
      tick(service.debounceDelay);
      service.activity.valueChanges.subscribe(() => {
        expect(service.evaluateTime).toHaveBeenCalled();
        expect(service.narrativeNo.setValue).toHaveBeenCalledWith(null);
      });
    }));
    describe('Selecting a narrative', () => {
      it('should set the narrative text', () => {
        service.createFormGroup(null);
        service.narrativeText.setValue = jest.fn();
        service.narrativeSelected({ text: 'abc-XYZ-123' });
        expect(service.defaultedNarrativeText).toBe('abc-XYZ-123');
        expect(service.narrativeText.setValue).toHaveBeenCalledWith('abc-XYZ-123', { emitEvent: false });
      });
    });
    describe('Changing the narrative text', () => {
      it('should reset the narrativeNo if different from default', () => {
        service.createFormGroup(null);
        service.narrativeNo.setValue = jest.fn();
        service.narrativeText.setValue('ABC-XYZ-123');
        service.defaultedNarrativeText = 'abc-XYZ-123';
        service.narrativeTextChanged();
        expect(service.narrativeNo.setValue).toHaveBeenCalledWith(null);
      });
      it('should leave the narrativeNo if text is same as default', () => {
        service.createFormGroup(null);
        service.narrativeNo.setValue(123);
        service.narrativeText.setValue('ABC-XYZ-123');
        service.defaultedNarrativeText = 'ABC-XYZ-123';
        service.narrativeTextChanged();
        expect(service.narrativeNo.value).toBe(123);
      });
    });
  });
  describe('Initialize start time', () => {
    it('should make call to initialize start time if siteCtrl\'s timeEmptyForNewEntries is false', () => {
      settingsService.timeEmptyForNewEntries = false;
      timeCalcService.selectedDate = new Date();
      timeCalcService.initializeStartTime = jest.fn();
      const startTime = service.getStartTime(null);
      expect(timeCalcService.initializeStartTime).toHaveBeenCalled();
      expect(startTime).not.toBeNull();
    });
  });

  describe('Defaulting the Finish Time', () => {
    beforeEach(() => {
      service.createFormGroup(new TimeEntryEx());
    });
    it('should not default when activity is set', () => {
      service.defaultFinishTime();
      expect(service.finish.value).toBeNull();
      expect(service.elapsedTime.value).toBeNull();
      expect(timeCalcService.getCurrentTimeFor).not.toHaveBeenCalled();
      expect(timeCalcService.calculateElapsed).not.toHaveBeenCalled();
    });
    it('should not defauler when Start is not available', () => {
      service.activity.setValue('ABC-xyz');
      service.defaultFinishTime();
      expect(service.finish.value).toBeNull();
      expect(service.elapsedTime.value).toBeNull();
      expect(timeCalcService.getCurrentTimeFor).not.toHaveBeenCalled();
      expect(timeCalcService.calculateElapsed).not.toHaveBeenCalled();
    });
    it('should set the Finish and Duration when Start is available', () => {
      const finish = new Date();
      timeCalcService.getCurrentTimeFor = jest.fn().mockReturnValue(finish);
      service.activity.setValue('ABC-xyz');
      service.start.setValue(new Date());
      service.defaultFinishTime();
      expect(timeCalcService.getCurrentTimeFor).toHaveBeenCalled();
      expect(timeCalcService.calculateElapsed).toHaveBeenCalledWith(service.start.value, service.finish.value);
      expect(service.finish.value).toEqual(finish);
      expect(service.elapsedTime.value).not.toBeNull();
    });

    it('should execute funtion to defaultFinishTime, only if start, finish controls are set up', () => {
      const input = new TimeEntryEx();
      input.isTimer = true;
      service.createFormGroup(input);

      service.defaultFinishTime();
      expect(timeCalcService.getCurrentTimeFor).not.toHaveBeenCalled();
    });

    it('should not set default finish time, if entering time for different date', () => {
      service.activity.setValue('ABC-xyz');
      service.start.setValue(new Date(2010, 1, 1, 8));
      service.defaultFinishTime();
      expect(timeCalcService.getCurrentTimeFor).not.toHaveBeenCalled();
      expect(service.finish.value).toBeNull();
      expect(service.elapsedTime.value).toBeNull();
    });
  });

  describe('Resetting the form', () => {
    beforeEach(() => {
      service._activityValueChange = jest.fn();
      service._onUnitsChanged = jest.fn();
      service._timePickerValueChanged = jest.fn();
    });
  });
});