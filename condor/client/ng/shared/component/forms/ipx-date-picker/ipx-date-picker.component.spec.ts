import { ChangeDetectionStrategy, Component, NO_ERRORS_SCHEMA, ViewChild } from '@angular/core';
import { ComponentFixture, fakeAsync, flush, TestBed, tick } from '@angular/core/testing';
import { FormsModule, NgControl, ReactiveFormsModule } from '@angular/forms';
import { By } from '@angular/platform-browser';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { BsDatepickerModule } from 'ngx-bootstrap/datepicker';
import { TooltipModule } from 'ngx-bootstrap/tooltip';
import { DateService } from '../../../../ajs-upgraded-providers/date-service.provider';
import { Translate } from '../../../../ajs-upgraded-providers/translate.mock';
import { IpxDatePickerComponent } from './ipx-date-picker.component';

@Component({
  template: `
      <ipx-date-picker [(ngModel)]="val"></ipx-date-picker>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxDatePickerTestComponent {
  @ViewChild(IpxDatePickerComponent, { static: true }) datePicker: IpxDatePickerComponent;
  val: Date = new Date();
}

class MockDateService {
  getParseFormats(): any {
    return [];
  }
  culture: any = 'en';
  dateFormat: any = 'DD/MM/YYYY';
  useDefault: any;
  format = jest.fn();
  adjustTimezoneOffsetDiff: any;
  shortDateFormat: any = 'M/D/YY';
    getExpandedParseFormats(): any {
     return [];
    }
}

describe('IpxDatePickerComponent', () => {

  let fixture: ComponentFixture<IpxDatePickerTestComponent>;
  let datePicker: IpxDatePickerComponent;
  let dateService: DateService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [IpxDatePickerComponent, IpxDatePickerTestComponent, Translate],
      imports: [
        BsDatepickerModule.forRoot(),
        TooltipModule.forRoot(),
        FormsModule,
        ReactiveFormsModule,
        NoopAnimationsModule],
      providers: [
        NgControl,
        DateService,
        { provide: DateService, useClass: MockDateService }
      ],
      schemas: [NO_ERRORS_SCHEMA]

    });
    fixture = TestBed.createComponent(IpxDatePickerTestComponent);
    datePicker = fixture.componentInstance.datePicker;
    dateService = datePicker.dateService;
    fixture.detectChanges();
  });

  it('Initialize a datepicker component', () => {
    expect(fixture.componentInstance).toBeDefined();
    expect(fixture.componentInstance.datePicker.bsConfig.selectFromOtherMonth).toBe(true);
  });

  it('Datepicker open/close calendar', () => {
    const dom = fixture.debugElement;
    const target = dom.query(By.css('.btn'));
    target.nativeElement.dispatchEvent(new Event('click'));
    fixture.detectChanges();

    const overlayDiv = document.getElementsByTagName('bs-datepicker-container')[0];
    expect(overlayDiv).toBeDefined();
  });

  it('Value should respond when is bound through ngModel', fakeAsync(() => {
    const fixt = TestBed.createComponent(IpxDatePickerTestComponent);
    const datePick = fixt.componentInstance.datePicker;
    let expectedRes = new Date();
    fixt.detectChanges();
    flush();

    expect(datePick.value.getDate()).toEqual(expectedRes.getDate());
    expect(datePick.value.getMonth()).toEqual(expectedRes.getMonth());
    expect(datePick.value.getFullYear()).toEqual(expectedRes.getFullYear());
    expectedRes = new Date(Date.now());
    datePicker.value = expectedRes;

    tick();
    expect(datePicker.value).toEqual(expectedRes);

    const boundValue = fixt.componentInstance.val;
    expect(boundValue).toEqual(expectedRes);
  }));

  it('check selected date', () => {
    const expected = new Date();
    expect(datePicker.value.getDate()).toEqual(expected.getDate());
    expect(datePicker.value.getMonth()).toEqual(expected.getMonth());
    expect(datePicker.value.getFullYear()).toEqual(expected.getFullYear());
  });

  it('check selected date', () => {
    const expected = new Date();
    expect(datePicker.value.getDate()).toEqual(expected.getDate());
    expect(datePicker.value.getMonth()).toEqual(expected.getMonth());
    expect(datePicker.value.getFullYear()).toEqual(expected.getFullYear());
  });

  it('control status change subscription', () => {
    datePicker.showDateParseError = true;
    datePicker.control.control.setErrors({});
    expect(datePicker.showError$.getValue()).toBeTruthy();
  });

  describe('formatDate', () => {
    it('should not change the date value', () => {
      const expected = new Date();
      datePicker.inputValue = '';
      datePicker.onInputChange();
      expect(datePicker.value.getDate()).toBe(expected.getDate());
      expect(datePicker.inputValue).toEqual(null);
    });
    it('should change the date value', () => {
      datePicker.value = new Date('Invalid Date');
      datePicker.inputValue = '09092019';
      datePicker.dateParserFormats = ['DD/MM/YYYY'];
      datePicker.onInputChange();
      expect(datePicker.value.toLocaleDateString()).toBe('9/9/2019');
      expect(datePicker.inputValue).toEqual(null);
    });

    it('should handle shortdate properly', () => {
      dateService.dateFormat = { toUpperCase: jest.fn().mockReturnValue('SHORTDATE') };
      datePicker.ngOnInit();
      expect(datePicker.bsConfig.dateInputFormat).toEqual(dateService.shortDateFormat);
    });

    it('should set parseFormats correctly', () => {
      dateService.getParseFormats = jest.fn().mockReturnValue(['mm/dd/yyyy', 'shortDate', 'longDate']);
      dateService.getExpandedParseFormats = jest.fn().mockReturnValue(['mm/dd/yyyy', 'shortDate', 'longDate']);
      datePicker.ngOnInit();
      expect(datePicker.dateParserFormats[0]).toBe('MM/DD/YYYY');
      expect(datePicker.dateParserFormats[1]).toBe('shortDate');
      expect(datePicker.dateParserFormats[2]).toBe('longDate');
    });
  });
  describe('validate Date', () => {
    beforeEach(() => {
      datePicker.value = new Date(2019, 9, 9);
      datePicker.control.control.markAsDirty();
    });
    it('should give invalid date if date is not valid', () => {
      datePicker.validateDate(new Date('Invalid'));
      expect(datePicker.control.control.invalid).toBe(true);
      expect(datePicker.control.control.errors.date).toBe(true);
    });
    it('later than - should give a validation error if date are same and include same Date is false', () => {
      datePicker.laterThan = new Date(2019, 9, 9);
      datePicker.includeSameDate = false;
      datePicker.validateDate(null);
      expect(datePicker.control.control.invalid).toBe(true);
      expect(datePicker.control.control.errors.laterThanDate).toBe(true);
    });
    it('later than - should give a validation error if date are not same and include same Date is true', () => {
      datePicker.laterThan = new Date(2019, 9, 10);
      datePicker.includeSameDate = true;
      datePicker.validateDate(null);
      expect(datePicker.control.control.invalid).toBe(true);
      expect(datePicker.control.control.errors.equalLaterThanDate).toBe(true);
    });
    it('later than - should not give a validation error if date are same and include same Date is true', () => {
      datePicker.laterThan = new Date(2019, 9, 9);
      datePicker.includeSameDate = true;
      datePicker.validateDate(null);
      expect(datePicker.control.control.invalid).toBe(false);
      expect(datePicker.control.control.errors).toBe(null);
    });
    it('earlier than - should give a validation error if date are same and include same Date is false', () => {
      datePicker.earlierThan = new Date(2019, 9, 9);
      datePicker.includeSameDate = false;
      datePicker.validateDate(null);
      expect(datePicker.control.control.invalid).toBe(true);
      expect(datePicker.control.control.errors.earlierThanDate).toBe(true);
    });
    it('earlier than - should give a validation error if date are not same and include same Date is true', () => {
      datePicker.earlierThan = new Date(2019, 9, 7);
      datePicker.includeSameDate = true;
      datePicker.validateDate(null);
      expect(datePicker.control.control.invalid).toBe(true);
      expect(datePicker.control.control.errors.equalEarlierThanDate).toBe(true);
    });
    it('earlier than - should not give a validation error if date are same and include same Date is true', () => {
      datePicker.earlierThan = new Date(2019, 9, 9);
      datePicker.includeSameDate = true;
      datePicker.validateDate(null);
      expect(datePicker.control.control.invalid).toBe(false);
      expect(datePicker.control.control.errors).toBe(null);
    });

    it('should not clear the error set by validators outside the component', () => {
      datePicker.control.control.setErrors({ ErrorFromReactiveValidator: true });
      datePicker.earlierThan = new Date(2019, 9, 9);
      datePicker.includeSameDate = true;
      datePicker.validateDate(null);

      expect(datePicker.control.control.invalid).toBe(true);
      expect(datePicker.control.control.errors).not.toBeNull();
      expect(datePicker.control.control.errors.ErrorFromReactiveValidator).toBeTruthy();
    });

    it('should not set range validations, if nulls are allowed', () => {
      datePicker.earlierThan = new Date(2019, 9, 9);
      datePicker.includeSameDate = false;
      datePicker.allowNull = true;
      datePicker.value = null;
      datePicker.validateDate(null);
      expect(datePicker.control.control.invalid).toBe(false);
      expect(datePicker.control.control.errors).toBeNull();
    });
  });
  describe('Date control errors', () => {
    beforeEach(() => {
      datePicker.value = new Date(2019, 9, 9);
      datePicker.control.control.markAsDirty();
    });

    it('should update warning and error collections', () => {
      datePicker.control.control.warnings = ['message1', 'message2'];
      datePicker.control.control.setErrors({ messages: ['error1'] });
      expect(datePicker.control.control.invalid).toBe(true);
      expect(datePicker.warningDetails).toEqual(['message1', 'message2']);
      expect(datePicker.errorsDetails).toEqual(['error1']);
    });
  });
});