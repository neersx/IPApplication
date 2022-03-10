import { fakeAsync, tick } from '@angular/core/testing';
import { AbstractControl, FormBuilder } from '@angular/forms';
import { BsModalRefMock, ChangeDetectorRefMock } from 'mocks';
import { DateFunctions } from 'shared/utilities/date-functions';
import * as _ from 'underscore';
import { DuplicateEntryServiceMock, UserInfoServiceMock } from '../time-recording.mock';
import { DuplicateEntryComponent } from './duplicate-entry.component';

describe('DuplicateEntryComponent', () => {
  let c: DuplicateEntryComponent;
  let bsModalRef: BsModalRefMock;
  let formBuilder: FormBuilder;
  let service: DuplicateEntryServiceMock;
  let userInfo: UserInfoServiceMock;
  let cdRef: ChangeDetectorRefMock;

  beforeEach(() => {
    bsModalRef = new BsModalRefMock();
    formBuilder = new FormBuilder();
    service = new DuplicateEntryServiceMock();
    userInfo = new UserInfoServiceMock();
    cdRef = new ChangeDetectorRefMock();
    c = new DuplicateEntryComponent(bsModalRef, formBuilder, service as any, userInfo as any, cdRef as any);

    c.ngOnInit();
  });

  it('should create', () => {
    expect(c).toBeTruthy();
  });

  it('initialise', () => {
    expect(c.form).not.toBeNull();
    expect(c.startDate).not.toBeNull();
    expect(c.endDate).not.toBeNull();
    expect(c.weekDays).not.toBeNull();
    expect(c.weekDays.controls.length).toBe(7);
  });

  it('on change of start dateset startDate to a variable and validate form', fakeAsync(() => {
    const updateValueAndValiditySpy = jest.spyOn(c.endDate, 'updateValueAndValidity');

    const d = new Date(2010, 1, 1);
    c.startDate.setValue(d);
    tick(500);

    expect(c.startDateValue).toEqual(d);
    expect(updateValueAndValiditySpy).toHaveBeenCalled();
    expect(cdRef.markForCheck).toHaveBeenCalled();
  }));

  it('checks date range to be within 3 months', fakeAsync(() => {

    const start = new Date(2010, 1, 1);
    c.startDate.setValue(start);
    tick(500);

    const end = new Date(2010, 4, 2);
    c.endDate.setValue(end);

    expect(c.endDate.errors).not.toBeNull();
    expect(c.endDate.errors['timeRecording.duplicateDateRangeError']).toBeTruthy();

    const newStart = new Date(2010, 1, 10);
    c.startDate.setValue(newStart);
    tick(500);

    expect(c.endDate.errors).toBeNull();
  }));

  it('should set error if none of the checkboxes are selected', () => {
    _.each(c.weekDays.controls, (con: AbstractControl) => { con.setValue(false); });

    expect(c.form.valid).toBeFalsy();
    expect(c.weekDays.valid).toBeFalsy();
    expect(c.weekDays.errors.errorMessage).toBe('accounting.time.duplicateEntry.selectOneCheckbox');
  });

  it('close dialog on cancel', () => {
    c.cancel();

    expect(bsModalRef.hide).toHaveBeenCalled();
  });

  it('should initiate duplication request on save', () => {
    c.entryNo = 10;
    const startDate = new Date(2010, 1, 1);
    const endDate = new Date(2010, 2, 1);
    c.startDate.setValue(startDate);
    c.endDate.setValue(endDate);

    c.addDuplicateEntries();

    expect(service.initiateDuplicationRequest).toHaveBeenCalled();
    expect(service.initiateDuplicationRequest.mock.calls[0][0].entryNo).toEqual(10);
    expect(service.initiateDuplicationRequest.mock.calls[0][0].start).toEqual(DateFunctions.toLocalDate(startDate));
    expect(service.initiateDuplicationRequest.mock.calls[0][0].end).toEqual(DateFunctions.toLocalDate(endDate));
    expect(service.initiateDuplicationRequest.mock.calls[0][0].days).toContainEqual(1);
    expect(service.initiateDuplicationRequest.mock.calls[0][0].days).toContainEqual(2);
    expect(service.initiateDuplicationRequest.mock.calls[0][0].days).toContainEqual(3);
    expect(service.initiateDuplicationRequest.mock.calls[0][0].days).toContainEqual(4);
    expect(service.initiateDuplicationRequest.mock.calls[0][0].days).toContainEqual(5);
    expect(service.initiateDuplicationRequest.mock.calls[0][0].staffId).toEqual(1);
  });

  it('getLabelText should return label text correctly for the index', () => {
    expect(c.getLabelText(0)).toEqual('monday');
    expect(c.getLabelText(1)).toEqual('tuesday');
    expect(c.getLabelText(5)).toEqual('saturday');
    expect(c.getLabelText(6)).toEqual('sunday');
  });
});
