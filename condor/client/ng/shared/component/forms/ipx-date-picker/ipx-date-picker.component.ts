import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Input, OnChanges, OnDestroy, OnInit, Renderer2, ViewChild } from '@angular/core';
import { NgControl } from '@angular/forms';
import { defineLocale, formatDate, isDateValid, listLocales, parseDate } from 'ngx-bootstrap/chronos';
import { BsDatepickerDirective, BsLocaleService } from 'ngx-bootstrap/datepicker';
import * as locales from 'ngx-bootstrap/locale';
import { BehaviorSubject, Subject, Subscription } from 'rxjs';
import { debounceTime } from 'rxjs/operators';
import * as _ from 'underscore';
import { DateService } from '../../../../ajs-upgraded-providers/date-service.provider';
import { ElementBaseComponent } from '../element-base.component';
import { FormControlWarning } from '../form-control-warning';

@Component({
  selector: 'ipx-date-picker',
  templateUrl: 'ipx-date-picker.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxDatePickerComponent extends ElementBaseComponent<Date> implements OnInit, OnChanges, OnDestroy {
  dateFormat: any;
  dateParserFormats: Array<string>;
  culture: any;
  bsConfig: any;
  edited: boolean;
  showDateParseError = false;
  inputValue: string;
  errorDate: string;

  @Input() label: string;
  @Input() displayError: boolean;
  @Input() earlierThan: Date;
  @Input() laterThan: Date;
  @Input() includeSameDate: boolean;
  @Input() showAlertErrorDetails: boolean;
  @Input() allowNull = false;
  errorsDetails: Array<string>;
  warningDetails: Array<string>;
  showError$ = new BehaviorSubject(false);
  isEdited$ = new BehaviorSubject(false);
  emitChange = new Subject<Date>();
  private originalValue: Date;
  private subscription: Subscription;

  @ViewChild('dateControl', { static: true }) dateControl: BsDatepickerDirective;

  constructor(readonly dateService: DateService, private readonly localeService: BsLocaleService, public el: ElementRef, public control: NgControl, cdr: ChangeDetectorRef, private readonly renderer: Renderer2) {
    super(control, el, cdr);
  }

  ngOnInit(): void {
    let dateformat = this.dateService.dateFormat.toUpperCase();
    dateformat = (dateformat !== 'SHORTDATE' ? dateformat : this.dateService.shortDateFormat.toUpperCase());
    this.dateFormat = dateformat;
    this.dateParserFormats = this.dateService.getExpandedParseFormats().map((x: any) => { return (x.toUpperCase() === 'SHORTDATE' || x.toUpperCase() === 'LONGDATE') ? x : x.toUpperCase(); });
    this.culture = this.setCulture(this.dateService.culture.toLowerCase());
    this.localeService.use(this.culture);
    this.bsConfig = { dateInputFormat: dateformat, showWeekNumbers: false, containerClass: 'dark-blue', selectFromOtherMonth: true, returnFocusToInput: true };
    this.originalValue = this.value;
    this.errorsDetails = [];
    this.warningDetails = [];

    if (this.control.control) {
      if (this.control.control.dirty) {
        this.updatecontrolState();
      }
      this.control.control.statusChanges.subscribe((value) => {
        if (value) {
          this.updatecontrolState();
        }
      });
    }

    this.subscription = this.emitChange.pipe(debounceTime(200)).subscribe(v => {
      this.onChange.emit(v);
    });
  }

  ngOnChanges(): any {
    this.validateDate(null);
  }

  ngOnDestroy(): void {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
  }

  updatecontrolState = () => {
    this.showError$.next(this.showError());
    this.isEdited$.next(this.controledited());
  };

  setCulture(culture: string): string {
    this.defineLocales();
    const availableLocales = listLocales();
    if (availableLocales.indexOf(culture) > -1) {
      return culture;
    }
    const shortCulture = culture.split('-')[0].toLowerCase();

    return availableLocales.indexOf(shortCulture) > -1 ? shortCulture : 'en';
  }

  defineLocales(): void {
    for (const locale of Object.keys(locales)) {
      defineLocale(locales[locale].abbr, locales[locale]);
    }
  }

  setDirty(e): void {
    this.showDateParseError = false;

    if ((this.value ? this.value.toLocaleDateString() : null) !== (e ? e.toLocaleDateString() : null)) {
      if (this.el.nativeElement.getAttribute('apply-edited') != null) {
        this.control.control.markAsDirty();
        this.edited = true;
      }
    }
  }

  writeValue = (value: any) => {
    this.value = value;
    this.dateControl.bsValue = value ? value : null;
  };

  parseKeyUp(event): any {
    this.inputValue = event.target.value;
    if ([13, 9, 27].indexOf(event.which) >= 0 || this.displayError) {
      this.showDateParseError = true;

      return;
    }
    this.showDateParseError = false;
  }

  showError = () => {
    if (this.disabled || (!!this.control.control.errors && this.control.control.errors.required && !this.control.control.touched)) {
      return false;
    }

    this.errorsDetails = this.control.control.errors ? this.control.control.errors.messages as Array<string> : [];
    this.warningDetails = (this.control.control as FormControlWarning).warnings || [];
    if (this.warningDetails.length > 0) {
      this.applyWarningClass();
    }

    return this.control.control.invalid && this.showDateParseError;
  };

  applyWarningClass(): void {
    const popUp = document.querySelector('popover-container');
    if (popUp) {
      this.renderer.addClass(popUp, 'popover-warning');
    }
  }

  getCustomErrorParams = (): any => ({
    date: this.errorDate
  });

  // We can remove the method once the ngx-datepicker starts supporting multiple date formats
  onInputChange(): void {
    if (this.inputValue && this.inputValue !== '') {
      const inputDate = parseDate(this.inputValue, this.dateParserFormats, this.culture);
      if (inputDate.toLocaleDateString() !== this.value.toLocaleDateString()) {
        this.value = inputDate;
        this.dateControl.bsValue = inputDate;
      }
    } else {
      this.setDirty(null);
      this.emitChange.next(null);
    }
    this._onChange(this.value);
    this.validateDate(null);
    this.inputValue = null;
  }

  validateDate(input: Date): void {
    const inputDate = this.getDateWithoutTime(input ? input : this.value);

    this.showDateParseError = true;
    if (this.control.dirty) {
      const errors = _.omit(this.control.control.errors, 'equalEarlierThanDate', 'equalLaterThanDate', 'date');
      this.control.control.setErrors(_.isEmpty(errors) ? null : errors);
    }

    if (inputDate && !isDateValid(inputDate)) {
      this.control.control.setErrors({ date: true });

      return;
    }
    this.validateEarlier(inputDate);
    this.validateLater(inputDate);
  }

  private validateEarlier(inputDate: Date): void {
    if (this.allowNull && inputDate === null) {
      return;
    }
    this.earlierThan = this.getDateWithoutTime(this.earlierThan);

    if (this.earlierThan && isDateValid(this.earlierThan) && this.control.dirty) {
      if (inputDate === null || (this.includeSameDate ? inputDate > this.earlierThan : inputDate >= this.earlierThan)) {
        this.errorDate = formatDate(this.earlierThan, this.dateFormat, this.culture);
        this.control.control.setErrors(this.includeSameDate ? { equalEarlierThanDate: true } : { earlierThanDate: true });
      } else {
        const errors = _.omit(this.control.control.errors, 'equalEarlierThanDate');
        this.control.control.setErrors(_.isEmpty(errors) ? null : errors);
      }
    }
  }

  private validateLater(inputDate: Date): void {
    if (this.allowNull && inputDate === null) {
      return;
    }
    this.laterThan = this.getDateWithoutTime(this.laterThan);

    if (this.laterThan && isDateValid(this.laterThan) && this.control.dirty) {

      if (inputDate === null || (this.includeSameDate ? inputDate < this.laterThan
        : inputDate <= this.laterThan)) {
        this.errorDate = formatDate(this.laterThan, this.dateFormat, this.culture);
        this.control.control.setErrors(this.includeSameDate ? { equalLaterThanDate: true } : { laterThanDate: true });
      } else {
        const errors = _.omit(this.control.control.errors, 'equalLaterThanDate');
        this.control.control.setErrors(_.isEmpty(errors) ? null : errors);
      }
    }
  }
  getDateWithoutTime(inputDate: Date): Date {
    if (inputDate) {
      return new Date(inputDate.getFullYear(), inputDate.getMonth(), inputDate.getDate());
    }

    return null;
  }

  dateChanged = (e: Date): void => {
    if (e) {
      // the below for invalid date can later be removed when ngx-bootstrap releases a fix, which is currently an open issue.
      if (e.toString() === 'Invalid Date') {
        this._onChange(null);
        this.setDirty(e);
        this.validateDate(e);
        this.emitChange.next(null);

        return;
      }
      if (isDateValid(e)) {
        if (e !== this.originalValue) {
          this._onChange(e);
          this.setDirty(e);
          this.validateDate(e);
        }
      }
    }
    if (e !== this.originalValue) {
      this.emitChange.next(e);
    }
  };
}
