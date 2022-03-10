import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';

@Component({
  selector: 'ipx-datepicker',
  templateUrl: './ipx-datepicker-example.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxDatepickerExampleComponent implements OnInit {
  date: string;
  now = new Date();
  initialised: any;
  default: any;
  initDate: any;
  disabled: any;

  ngOnInit(): void {
    this.initDate = this.now;
    this.initialised = this.model(this.now);
    this.default = this.model(this.now);
    this.disabled = this.makeDisabled(this.model(undefined));
  }

  model = (date: any) =>
    ({
      // tslint:disable-next-line: strict-boolean-expressions
      date: date || undefined,
      isDisabled: false,
      isReadOnly: false
    });

  makeDisabled = (o: { isDisabled: boolean; }) => {
    o.isDisabled = true;

    return o;
  };

  UpdateInitialized(event: any): void {
    this.initDate = event;
  }

  UpdateDefault(event: any): void {
    this.default.date = event;
  }

}
