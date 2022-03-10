import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, OnDestroy, OnInit, Output } from '@angular/core';
import { AbstractControl, FormArray, FormBuilder, FormControl, FormGroup, ValidatorFn, Validators } from '@angular/forms';
import * as moment from 'moment';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import { debounceTime, take, takeUntil } from 'rxjs/operators';
import { DateFunctions } from 'shared/utilities/date-functions';
import * as _ from 'underscore';
import { UserInfoService } from '../settings/user-info.service';
import { DuplicateEntryService } from './duplicate-entry.service';

@Component({
  selector: 'duplicate-entry',
  templateUrl: './duplicate-entry.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DuplicateEntryComponent implements OnInit, OnDestroy {
  constructor(
    private readonly bsModalRef: BsModalRef,
    private readonly formBuilder: FormBuilder,
    private readonly service: DuplicateEntryService,
    private readonly userInfo: UserInfoService,
    private readonly cdRef: ChangeDetectorRef) { }

  entryNo: number;
  private selectedStaffId: number;
  private readonly _dayOfWeek = [
    { value: 0, seq: 6, defaultSelected: false, labelText: 'sunday' },
    { value: 1, seq: 0, defaultSelected: true, labelText: 'monday' },
    { value: 2, seq: 1, defaultSelected: true, labelText: 'tuesday' },
    { value: 3, seq: 2, defaultSelected: true, labelText: 'wednesday' },
    { value: 4, seq: 3, defaultSelected: true, labelText: 'thursday' },
    { value: 5, seq: 4, defaultSelected: true, labelText: 'friday' },
    { value: 6, seq: 5, defaultSelected: false, labelText: 'saturday' }];

  form: FormGroup;

  get weekDays(): FormArray {
    return this.form.get('weekDays') as FormArray;
  }

  get startDate(): FormControl {
    return this.form.get('startDate') as FormControl;
  }
  startDateValue: Date;

  get endDate(): FormControl {
    return this.form.get('endDate') as FormControl;
  }

  @Output() private readonly requestRaised = new EventEmitter<boolean>();

  destory$ = new Subject<boolean>();

  ngOnInit(): void {
    const weekDayControls = this.formBuilder.array(
      _.map(_.sortBy(this._dayOfWeek, 'seq'), (d) => { return [d.defaultSelected]; }), { validators: this._minOneCheckBox() });

    this.form = this.formBuilder.group({
      startDate: ['', { validators: Validators.required }],
      endDate: ['', { validators: [Validators.required, this._dateRangeCheck()] }],
      weekDays: weekDayControls
    });

    this.userInfo.userDetails$.pipe(take(1)).subscribe((val) => {
      this.selectedStaffId = val.staffId;
    });

    this.startDate.valueChanges
      .pipe(debounceTime(500), takeUntil(this.destory$))
      .subscribe((d: Date) => {
        this.startDateValue = d;
        this.endDate.updateValueAndValidity();
        this.cdRef.markForCheck();
      });
  }

  cancel(): void {
    this.bsModalRef.hide();
  }

  trackByFn = (index, item): any => {
    return index;
  };

  getLabelText = (index: number): string => {
    return _.findWhere(this._dayOfWeek, { seq: index }).labelText;
  };

  addDuplicateEntries = (): void => {
    this.requestRaised.emit();
    const rawInput = this.form.getRawValue();
    const input = {
      entryNo: this.entryNo,
      start: DateFunctions.toLocalDate(rawInput.startDate, true),
      end: DateFunctions.toLocalDate(rawInput.endDate, true),
      days: this._getDays(rawInput.weekDays),
      staffId: this.selectedStaffId
    };

    this.service.initiateDuplicationRequest(input);
    this.bsModalRef.hide();
  };

  private readonly _getDays = (rawDays: Array<number>): Array<number> => {
    const seqDaysOfWeek = _.sortBy(this._dayOfWeek, 'seq');

    return _.chain(rawDays)
      .map((v, i) => { return { selected: v, seq: i }; })
      .zip(seqDaysOfWeek)
      .filter((elem) => { return !!elem[0].selected; })
      .map((elem) => { return elem[1].value; })
      .value();
  };

  ngOnDestroy(): void {
    this.destory$.next(true);
    this.destory$.complete();
  }

  private readonly _minOneCheckBox = (): ValidatorFn => {
    return (array: FormArray): { [key: string]: any } | null => {
      if (!array || !array.controls || array.controls.length === 0) {
        return null;
      }

      if (_.every(array.controls, (c) => { return !c.value; })) {
        return { errorMessage: 'accounting.time.duplicateEntry.selectOneCheckbox' };
      }

      return null;
    };
  };

  private readonly _dateRangeCheck = (): ValidatorFn => {
    return (control: AbstractControl): { [key: string]: any } | null => {
      if (!this.form || !control || !this.startDate || !(control.value instanceof Date) || !(this.startDate.value instanceof Date)) {
        return null;
      }

      if (moment(this.startDate.value).startOf('day').add(3, 'M') < moment(control.value).startOf('day')) {
        return { 'timeRecording.duplicateDateRangeError': true };
      }

      return null;
    };
  };
}
