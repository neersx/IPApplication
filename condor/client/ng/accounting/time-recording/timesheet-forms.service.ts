import { Injectable } from '@angular/core';
import { AbstractControl, FormBuilder, FormGroup, RequiredValidator, ValidationErrors, ValidatorFn, Validators } from '@angular/forms';
import { combineLatest, Observable, of } from 'rxjs';
import { debounceTime, distinctUntilChanged, map, scan, skip, startWith, switchMap } from 'rxjs/operators';
import * as _ from 'underscore';
import { TimeSettingsService } from './settings/time-settings.service';
import { TimeCalculationService } from './time-calculation.service';
import { EnteredTimes, TimeEntry, TimeEntryEx } from './time-recording-model';
import { TimeRecordingService } from './time-recording-service';
import { TimeRecordingValidators } from './time-validators';

@Injectable({
  providedIn: 'root'
})
export class TimesheetFormsService {
  formGroup: FormGroup;
  activitySubscription: any;
  timeFieldsSubscription: any;
  unitsSubscription: any;
  caseSubscription: any;
  originalDetails: TimeEntryEx;
  toBeContinuedFrom: TimeEntryEx;
  isContinuedEntryMode: any;
  isTimerRunning: boolean;
  defaultedNarrativeText: any;
  newChildEntry: any;
  activityDisabled: boolean;
  debounceDelay: 500;
  staffNameId?: number;
  staleFinancials: boolean | false;

  get start(): AbstractControl {
    return this.formGroup.get('start');
  }

  get finish(): AbstractControl {
    return this.formGroup.get('finish');
  }

  get elapsedTime(): AbstractControl {
    return this.formGroup.get('elapsedTime');
  }

  get totalUnits(): AbstractControl {
    return this.formGroup.get('totalUnits');
  }

  get narrativeText(): AbstractControl {
    return this.formGroup.get('narrativeText');
  }

  get notes(): AbstractControl {
    return this.formGroup.get('notes');
  }

  get narrativeNo(): AbstractControl {
    return this.formGroup.get('narrativeNo');
  }

  get activity(): AbstractControl {
    return this.formGroup.get('activity');
  }

  get name(): AbstractControl {
    return this.formGroup.get('name');
  }

  get caseReference(): AbstractControl {
    return this.formGroup.get('caseReference');
  }

  constructor(private readonly timeCalcService: TimeCalculationService,
    private readonly timeService: TimeRecordingService,
    private readonly formBuilder: FormBuilder,
    private readonly settingsService: TimeSettingsService) {
  }

  getElapsedTime(seconds = 0): Date {
    return new Date(1899, 0, 1, 0, 0, seconds);
  }

  get isFormValid(): boolean {
    return !this.formGroup || this.formGroup.valid;
  }

  get hasPendingChanges(): boolean {
    return this.formGroup && this.formGroup.dirty;
  }

  getSelectedCaseRef(): any {
    return this.formGroup ? this.caseReference.value : null;
  }

  getSelectedName(): any {
    return this.formGroup ? this.name.value : null;
  }

  dateChanged(isDateSelected: boolean): void {
    if (this.formGroup && this.formGroup.dirty) {
      this.formGroup.reset();
    }
    if (!isDateSelected) {
      if (this.formGroup) {
        this.formGroup.setErrors({ errorMessage: 'accounting.time.recording.validationMsgs.entryDateRequired' });
      }
    }
  }

  private readonly _createTextFields = (dataItem: TimeEntryEx): any => {
    return {
      narrativeNo: [!dataItem ? null : { key: dataItem.narrativeNo, value: dataItem.narrativeTitle, text: dataItem.narrativeText }],
      name: [{ value: !dataItem || !_.isNumber(dataItem.nameKey) ? null : { key: dataItem.nameKey, displayName: dataItem.name }, disabled: this.isContinuedEntryMode }],
      caseReference: [{ value: !dataItem ? null : dataItem.caseKey === null ? null : { key: dataItem.caseKey, code: dataItem.caseReference }, disabled: this.isContinuedEntryMode }],
      activity: [{ value: !dataItem ? null : { key: dataItem.activityKey, value: dataItem.activity }, disabled: this.isContinuedEntryMode }],
      notes: [!dataItem ? null : dataItem.notes],
      narrativeText: [!dataItem ? null : dataItem.narrativeText]
    };
  };

  createFormGroupForEntry = (dataItem: TimeEntryEx): void => {
    const startTime = this.getStartTime(dataItem);
    let finishTime = null;
    let elapsedTime = null;

    if (!!dataItem) {
      this.originalDetails = new TimeEntryEx({ ...dataItem });
      finishTime = !!dataItem.finish ? new Date(dataItem.finish) : null;
      elapsedTime = !!dataItem.finish && !!dataItem.start ? this.timeCalcService.calculateElapsed(startTime, finishTime) : this.timeCalcService.calcDurationFromUnits(dataItem.totalUnits, dataItem.secondsCarriedForward);
    }

    const validators = [TimeRecordingValidators.checkIfEndDateAfterStartDate.bind(this), TimeRecordingValidators.enableSave.bind(this), this._checkIfStartIsBeforeFinishOfContinuedFrom];

    this.formGroup = this.formBuilder.group({
      ...{
        start: [startTime],
        finish: [finishTime],
        elapsedTime: [elapsedTime, { validators: [this._conditionalValidator(() => this._isElapsedTimeMaxCheckNeeded(), this._elapsedTimeMax())] }],
        totalUnits: [{ value: !dataItem ? null : +dataItem.totalUnits, disabled: !!dataItem && dataItem.parentEntryNo && !this.settingsService.enabledUnitsForContinuedTime }, { validators: this._validateUnits() }]
      },
      ...this._createTextFields(dataItem)
    }, {
      validator: validators
    });

    if (!!dataItem && !!dataItem.isPosted) {
      this.name.disable();

      if (!dataItem.caseKey) {
        this.caseReference.disable();
      } else {
        this.caseReference.setValidators(Validators.required);
      }
    }

    if (!!dataItem && _.isNumber(dataItem.parentEntryNo)) {
      const minUnits = this.timeCalcService.calcUnitsFromDuration(this.getElapsedTime(dataItem.elapsedTimeInSeconds), dataItem.secondsCarriedForward);
      this.totalUnits.setValidators(this._minUnitsForContinuedEntryValidator(minUnits));
    }

    this._timePickerValueChanged(startTime, finishTime, elapsedTime);
    this._activityValueChange();
    this._onUnitsChanged();
  };

  createFormGroupForTimerEntry = (dataItem: TimeEntryEx): void => {
    this.formGroup = this.formBuilder.group(this._createTextFields(dataItem), { validator: this.enableSaveForTimer });

    this._activityValueChange();
    this.isTimerRunning = true;
  };

  createFormGroup = (dataItem: TimeEntryEx): FormGroup => {
    if (!!dataItem && dataItem.isTimer) {
      this.createFormGroupForTimerEntry(dataItem);
    } else {
      this.createFormGroupForEntry(dataItem);
    }

    if (!dataItem) {
      this.formGroup.markAsPristine();
    }

    return this.formGroup;
  };

  enableSaveForTimer = () => {
    if (this.isTimerRunning && this.isFormValid) {
      return null;
    }

    return { errorMessage: '' };
  };

  getStartTime = (dataItem: any): Date => {
    if (!!dataItem && !this.isContinuedEntryMode) {
      return !!dataItem.start ? new Date(dataItem.start) : this.initializeStartTime();
    }

    return this.initializeStartTime();
  };

  checkIfActivityCanBeDefaulted(caseKey: number): void {
    if (!this.activity.value || !this.activity.value.value) {
      this.activity.disable();
      this.timeService.getDefaultActivityFromCase(caseKey)
        .subscribe((response: any) => {
          this.activity.setValue(response.activity.key ? response.activity : null);
          if (response.narrative && response.narrative.key) {
            this.narrativeNo.setValue(response.narrative.key ? response.narrative : null);
            this.narrativeText.setValue(response.narrative.text);
          }
          this.activity.enable();
        });
    } else {
      this.defaultNarrativeFromActivity();
    }
  }

  defaultNarrativeFromActivity(): void {
    if ((!this.narrativeNo.value || !this.narrativeNo.value.key) && !!this.narrativeText.value) {
      return;
    }
    const activityKey = this.activity.value ? this.activity.value.key : '';
    this.narrativeNo.disable();
    const entryCase = this.caseReference.value;
    const entryDebtor = this.name.value;
    this.timeService.getDefaultNarrativeFromActivity(activityKey, !!entryCase ? entryCase.key : null, !!entryDebtor ? entryDebtor.key : null, _.isNumber(this.staffNameId) ? this.staffNameId : null)
      .subscribe((narrative: any) => {
        this.narrativeNo.setValue(narrative);
        this.narrativeNo.enable();
      });
  }

  getDataToSave(): TimeEntry {
    if (!this.formGroup) {
      return new TimeEntry({ start: null });
    }

    this.formGroup.updateValueAndValidity({ emitEvent: true });
    const data: TimeEntry = new TimeEntry({
      staffId: _.isNumber(this.staffNameId) ? this.staffNameId : null,

      start: !!this.start && this.start.value ? this.timeService.toLocalDate(this.start.value) : null,
      finish: !!this.finish && this.finish.value ? this.timeService.toLocalDate(this.finish.value) : null,
      totalTime: !!this.elapsedTime && this.elapsedTime.value ? this.timeService.toLocalDate(this.elapsedTime.value) : null,
      elapsedTimeInSeconds: !!this.elapsedTime ? this.elapsedTime.value : null,
      totalUnits: !this.newChildEntry && !!this.totalUnits ? this.totalUnits.value : null,

      nameKey: !this.caseReference.value && this.name.value ? this.name.value.key : null,
      caseKey: this.caseReference.value ? this.caseReference.value.key : null,
      activity: this.activity.value ? this.activity.value.key : null,
      narrativeText: this.narrativeText.value,
      notes: this.notes.value,
      entryDate: this.timeService.toLocalDate(this.timeCalcService.selectedDate, true),
      narrativeNo: this.narrativeNo.value ? this.narrativeNo.value.key : null,
      parentEntryNo: !!this.newChildEntry ? this.newChildEntry.parentEntryNo : null,
      timeCarriedForward: !!this.newChildEntry ? this.timeService.toLocalDate(this.newChildEntry.timeCarriedForward) : null
    });

    return data;
  }

  narrativeSelected = (narrative: any): void => {
    if (!!narrative) {
      this.defaultedNarrativeText = narrative.text;
      this.narrativeText.setValue(narrative.text, { emitEvent: false });
    }
  };

  narrativeTextChanged = (): void => {
    if (this.defaultedNarrativeText !== this.narrativeText.value) {
      this.narrativeNo.setValue(null);
    }
  };

  initializeStartTime(): Date | null {
    return this.timeCalcService.initializeStartTime(this.settingsService.timeEmptyForNewEntries, this.newChildEntry != null);
  }

  private readonly _calculateMissingValue = (input: EnteredTimes): EnteredTimes => {
    if (input.start && input.finish) {
      input.elapsedTime = this.timeCalcService.calculateElapsed(input.start, input.finish);

      if (input.elapsedTime == null) {
        input.finish = null;
      }

      return input;
    }

    if (input.start == null && input.finish !== null && input.elapsedTime !== null) {
      input.start = this.timeCalcService.calculateStart(input.finish, input.elapsedTime);
    }
    if (input.finish == null && input.start !== null && input.elapsedTime !== null) {
      input.finish = this.timeCalcService.calculateFinished(input.start, input.elapsedTime);
    }
    if (input.elapsedTime == null && input.start !== null && input.finish !== null) {
      input.elapsedTime = this.timeCalcService.calculateElapsed(input.start, input.finish);
    }

    return input;
  };

  private readonly _calculateMissingValuesWithActivitySet = (input: EnteredTimes): EnteredTimes => {
    if (input.nullValues() !== 2 || !!this.newChildEntry) {
      return input;
    }
    if (input.start !== null) {
      input.finish = this.timeCalcService.getCurrentTimeFor(input.start);
      input.elapsedTime = this.timeCalcService.calculateElapsed(input.start, input.finish);
    } else if (input.finish !== null) {
      input.start = new Date(input.finish);
      input.elapsedTime = this.timeCalcService.calculateElapsed(input.start, input.finish);
    }

    return input;
  };

  readonly defaultFinishTime = (): void => {
    if (!!this.activity.value && !!this.start && !!this.finish) {
      const timeFields = new EnteredTimes(this.start.value, this.finish.value, this.elapsedTime.value);
      if (timeFields.finish == null) {
        if (timeFields.start !== null && !this.areDatesDifferent(new Date(), timeFields.start, true)) {
          timeFields.finish = this.timeCalcService.getCurrentTimeFor(new Date());
          timeFields.elapsedTime = this.timeCalcService.calculateElapsed(timeFields.start, timeFields.finish);
        }
        this.formGroup.patchValue(timeFields, { emitEvent: false });
      }
    }
  };

  _activityValueChange = (): void => {
    this.activitySubscription = this.activity.valueChanges
      .pipe(debounceTime(this.debounceDelay))
      .subscribe((activity: any) => {
        this.evaluateTime();

        if (!this.narrativeNo.value && this.narrativeText.value) {
          return;
        }

        if (!!activity) {
          this.defaultNarrativeFromActivity();
        } else { // clearing the activity should clear the narrative only if it is not edited
          if (this.narrativeNo.value) {
            this.narrativeNo.setValue(null);
            this.narrativeText.setValue(null);
          }
        }
      });
  };

  areDatesDifferent = (d1: any, d2: any, dateOnly = false): boolean => {
    if (d1 instanceof Date && d2 instanceof Date) {
      if (dateOnly) {
        return !(d1.getFullYear() === d2.getFullYear() && d1.getMonth() === d2.getMonth() && d1.getDate() === d2.getDate());
      }

      return d1.getTime() !== d2.getTime();
    }

    if (d1 === null && d2 === null) {
      return false;
    }

    return true;
  };

  _timePickerValueChanged = (startTime, finishTime, elapsedTime): void => {
    this.timeCalcService.calculateElapsedMinMax(startTime);
    const startValueChange = this.start.valueChanges
      .pipe(
        startWith(null, startTime),
        distinctUntilChanged(),
        map(val => this.timeCalcService.parsePartiallyEnteredTime(val)
        ));
    const finishValueChange = this.finish.valueChanges
      .pipe(
        startWith(null, finishTime),
        distinctUntilChanged(),
        map(val => this.timeCalcService.parsePartiallyEnteredTime(val)
        ));
    const elapsedValueChange = this.elapsedTime.valueChanges.
      pipe(
        startWith(this.getElapsedTime(), elapsedTime),
        distinctUntilChanged(),
        map(val => this.timeCalcService.parsePartiallyEnteredDuration(val)
        ));

    this.timeFieldsSubscription = combineLatest([startValueChange, finishValueChange, elapsedValueChange])
      .pipe(
        debounceTime(this.debounceDelay),
        scan((acc, values) => [
          ...values,
          this.areDatesDifferent(acc[2], values[2]) ? 'elapsedChanged' :
            this.areDatesDifferent(acc[0], values[0]) ? 'startChanged' :
              this.areDatesDifferent(acc[1], values[1]) ? 'finishChanged' : null
        ]),
        skip(1))
      .subscribe(([start, finish, elapsed, whatChanged]) => {
        let newValue = new EnteredTimes(start as Date, finish as Date, elapsed as Date);
        let changeHandled = false;
        switch (whatChanged) {
          case 'startChanged':
            if (newValue.start === null) {
              newValue.elapsedTime = null;
              this.timeCalcService.clearMinMax();
            } else {
              newValue = this._calculateMissingValue(newValue);
              this.timeCalcService.calculateElapsedMinMax(newValue.start);
            }
            changeHandled = true;
            break;

          case 'finishChanged':
            if (newValue.finish === null) {
              newValue.elapsedTime = null;
            } else {
              if (!!newValue.start && newValue.start.getTime() < newValue.finish.getTime() || !newValue.start) {
                newValue = this._calculateMissingValue(newValue);
              }
            }
            changeHandled = true;
            break;

          case 'elapsedChanged':
            if (newValue.elapsedTime === null) {
              newValue.finish = null;
            } else {
              if (!!newValue.elapsedTime && newValue.elapsedTime.getTime() <= this.timeCalcService.max.getTime()) {
                if (newValue.start != null) {
                  newValue.finish = null;
                }
                newValue = this._calculateMissingValue(newValue);
              }
            }
            changeHandled = true;
            break;

          default: break;
        }

        if (newValue.nullValues() >= 2 && !changeHandled && !!whatChanged) {
          if (newValue.start != null) {
            this.timeCalcService.calculateElapsedMinMax(newValue.start);
          } else if (newValue.finish !== null) {
            this.timeCalcService.calculateElapsedMinMaxWithFinishedTime(newValue.finish);
          } else {
            this.timeCalcService.clearMinMax();
          }
        }

        this.formGroup.patchValue(newValue);
        this.totalUnits.setValue(this.timeCalcService.calcUnitsFromDuration(newValue.elapsedTime, !!this.originalDetails ? this.originalDetails.secondsCarriedForward : null), { emitEvent: false });

        if (!!whatChanged) {
          this.evaluateTime();
        }
      });
  };

  _onUnitsChanged = (): void => {
    this.unitsSubscription = this.totalUnits
      .valueChanges
      .pipe(distinctUntilChanged(), debounceTime(this.debounceDelay))
      .subscribe((value: number) => {
        if (isNaN(value) || value < 0 || value % 1 > 0 || !!this.totalUnits.errors) {
          return null;
        }

        this.formGroup.patchValue({
          start: null,
          finish: null,
          elapsedTime: this.timeCalcService.calcDurationFromUnits(value, !!this.originalDetails ? this.originalDetails.secondsCarriedForward : null)
        });

        this.evaluateTime();
      });
  };

  unsubscribeFormValueChanges = (): void => {
    if (this.activitySubscription) { this.activitySubscription.unsubscribe(); }
    if (this.timeFieldsSubscription) { this.timeFieldsSubscription.unsubscribe(); }
    if (this.unitsSubscription) { this.unitsSubscription.unsubscribe(); }
  };

  private readonly _elapsedTimeMax = (): ValidatorFn => {
    return (control: AbstractControl): { [key: string]: any } | null => {
      if (!control) {
        return null;
      }

      const value = control.value;
      if (!(value instanceof Date)) {
        return {};
      }

      if (value.getTime() > this.timeCalcService.max.getTime()) {
        return { errorMessage: 'accounting.time.recording.validationMsgs.finishNotSameDayAsStart' };
      }
    };
  };

  private readonly _validateUnits = (): ValidatorFn => {
    return (control: AbstractControl): { [key: string]: any } | null => {
      if (!control) {
        return null;
      }
      const maxUnits = this.settingsService.unitsPerHour * 24;
      const totalUnits = control.value;

      if (totalUnits % 1 > 0) {
        return { wholeinteger: true };
      }
      if (isNaN(totalUnits) || totalUnits < 0) {
        return { nonnegativeinteger: true };
      }
      if (totalUnits >= maxUnits) {
        return { 'timeRecording.maxUnitsExceeded': true };
      }
    };
  };

  private readonly _minUnitsForContinuedEntryValidator = (minUnits: number): ValidatorFn => {
    return (control: AbstractControl): { [key: string]: any } | null => {
      const totalUnits = control.value;
      if (totalUnits < minUnits) {
        return { min: minUnits };
      }

      return null;
    };
  };

  private readonly _conditionalValidator = (predicate: BooleanFn, validator: ValidatorFn): ValidatorFn => {
    return (formControl => {
      if (!formControl.parent) {
        return null;
      }
      let error = null;
      if (predicate()) {
        error = validator(formControl);
      }

      return error;
    });
  };

  evaluateTime = (): void => {
    if (this.isTimerRunning) {

      return;
    }

    if (this.settingsService.valueTimeOnEntry) {
      this.timeService.evaluateTime(this.timeCalcService.selectedDate, this.originalDetails != null ? this.originalDetails.entryNo : null, this._getInputValues(this.formGroup));
    } else {
      this.staleFinancials = this.formGroup.dirty ? true : false;
    }
  };

  private readonly _getInputValues = (formGroup: FormGroup): TimeEntry => {
    let elapsedTimeInSeconds = this.elapsedTime.value;
    if (this.elapsedTime.errors || this.start.errors || this.finish.errors) {
      elapsedTimeInSeconds = null;
    }

    const data: TimeEntry = new TimeEntry({
      elapsedTimeInSeconds,
      activity: this.activity.value ? this.activity.value.key : null,
      nameKey: this.name.value ? this.name.value.key : null,
      caseKey: this.caseReference.value ? this.caseReference.value.key : null,
      start: this.start.value ? this.timeService.toLocalDate(this.start.value) : null,
      finish: this.finish.value ? this.timeService.toLocalDate(this.finish.value) : null,
      totalUnits: this.totalUnits.value,
      totalTime: elapsedTimeInSeconds ? this.timeService.toLocalDate(elapsedTimeInSeconds) : null,
      staffId: _.isNumber(this.staffNameId) ? this.staffNameId : null
    });

    return data;
  };

  private readonly _isElapsedTimeMaxCheckNeeded = (): boolean => {
    if (this.start.value !== null || (this.start.value === null && this.finish.value !== null)) {
      return true;
    }

    return false;
  };

  clearTime = (): void => {
    if (this.isContinuedEntryMode) {
      this.finish.reset();
      this.elapsedTime.reset();
    } else {
      this.formGroup.reset();
    }

    if (!!this.start) {
      this.start.setValue(this.initializeStartTime(), { emitEvent: false });
    }
    this.staleFinancials = false;
  };

  resetOriginalValues(editedEntry: TimeEntryEx): void {
    editedEntry.notes = this.originalDetails.notes;
    editedEntry.narrativeText = this.originalDetails.narrativeText;
    editedEntry.narrativeTitle = this.originalDetails.narrativeTitle;
    editedEntry.localDiscount = this.originalDetails.localDiscount;
    editedEntry.localValue = this.originalDetails.localValue;
    editedEntry.foreignValue = this.originalDetails.foreignValue;
    editedEntry.foreignDiscount = this.originalDetails.foreignDiscount;
    editedEntry.chargeOutRate = this.originalDetails.chargeOutRate;
  }

  resetForm(): void {
    this.newChildEntry = null;
    this.staleFinancials = false;
    this.isContinuedEntryMode = false;
    this.isTimerRunning = false;
    let control: AbstractControl = null;
    if (!this.formGroup) {
      return;
    }
    this.formGroup.reset();
    this.unsubscribeFormValueChanges();

    // formgroup.reset isnt clearing the errors/dirty state for some reason. The below is a work around.
    this.formGroup.markAsUntouched();
    this.formGroup.markAsPristine();
    this.formGroup.setErrors(null);

    Object.keys(this.formGroup.controls).forEach((name) => {
      control = this.formGroup.controls[name];
      control.setErrors(null);
    });
  }

  continue = (dataItem: TimeEntryEx, childEntry: TimeEntryEx): void => {
    this.isContinuedEntryMode = true;
    this.toBeContinuedFrom = dataItem;
    this.newChildEntry = childEntry;
  };

  private readonly _checkIfStartIsBeforeFinishOfContinuedFrom = (c: FormGroup): ValidationErrors | null => {
    if (this.isContinuedEntryMode) {
      if (!c || !this || !this.formGroup || !this.start || !this.finish) {
        return null;
      }
      if (!this.toBeContinuedFrom || this.start.value === null && this.finish.value === null) {
        if (!!c.errors) {
          c.setErrors(null);
          this.start.setErrors(null);
        }

        return null;
      }
      this.start.markAsDirty();
      const finishTime = new Date(this.toBeContinuedFrom.finish);
      const startTime = new Date(this.start.value);
      const finishedSecs = finishTime.getTime() / 1000;
      const startSecs = startTime.getTime() / 1000;
      if (Math.trunc(startSecs) < Math.trunc(finishedSecs)) {
        this.start.setErrors({ errorMessage: 'accounting.time.recording.validationMsgs.startMustBeLaterThanContinued' });

        return { errorMessage: 'accounting.time.recording.validationMsgs.startMustBeLaterThanContinued' };
      }
    } else {
      return null;
    }
  };
}

export type BooleanFn = () => boolean;
