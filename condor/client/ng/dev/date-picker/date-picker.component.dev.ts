import { ChangeDetectionStrategy, ChangeDetectorRef, Component } from '@angular/core';
@Component({
  selector: 'date-picker',
  templateUrl: './date-picker.component.dev.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DatePickerComponent {
  date: string;
  now = new Date();
  empty: any;
  initialised: any;
  required: any;
  disabled: any;
  readonly: any;
  external: any;
  reset: any;
  saved: any;
  modified: any;
  istrue: boolean;

  constructor(private readonly cd: ChangeDetectorRef) {
    this.empty = this.model(undefined);
    this.initialised = this.model(this.now);
    this.required = this.model(undefined);
    this.disabled = this.makeDisabled(this.model(undefined));
    this.readonly = this.makeReadOnly(this.model(undefined));
    this.external = this.model(undefined);
    this.reset = this.model(this.now);
    this.saved = this.model(this.now);
    this.modified = this.model(this.now);
    this.istrue = true;
  }

  refresh(): void {
    this.cd.detectChanges();
  }

  model = (date: any) =>
    ({
      // tslint:disable-next-line: strict-boolean-expressions
      date: date || undefined,
      isDisabled: false,
      isReadOnly: false
    });
  makeReadOnly = (o: { isReadOnly: boolean; }) => {
    o.isReadOnly = true;

    return o;
  };

  makeDisabled = (o: { isDisabled: boolean; }) => {
    o.isDisabled = true;

    return o;
  };

  UpdateValue(data: any, key: any): void {
    switch (key) {
      case 'required': {
        this.required.date = data.date;
        break;
      }
      case 'initialised': {
        this.initialised.date = data.date;
        break;
      }
      case 'external': {
        this.external.date = data.date;
        break;
      }
      default: {
        break;
      }
    }
  }

  Reset(key: any): void {
    switch (key) {
      case 'required': {
        this.required.date = undefined;
        break;
      }
      case 'initialised': {
        this.initialised.date = undefined;
        break;
      }
      case 'external': {
        this.external.date = undefined;
        break;
      }
      default: {
        break;
      }
    }
  }
}
