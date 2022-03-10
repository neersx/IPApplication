import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';

@Component({
  selector: 'date-picker.e2e',
  templateUrl: './date-picker.component.e2e.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DatePickerE2eComponent {

  testDate: any;
  existingDate: any;
  repopulateDate: any;

  constructor(public datehelper: DateHelper) {
    this.existingDate = datehelper.convertForDatePicker('2017-05-18T00:00:00');

  }
  onExistingDateChange = () => {
    this.repopulateDate = this.datehelper.convertForDatePicker(this.existingDate);
  };

  UpdateValue(data: any, key: any): void {
    switch (key) {
      case 'testDate': {
        this.testDate = data.date;
        break;
      }
      case 'existing': {
        this.existingDate = data.date;
        this.onExistingDateChange();
        break;
      }
      case 'repopulate': {
        this.repopulateDate = data.date;
        break;
      }
      default: {
        break;
      }
    }
  }
}
