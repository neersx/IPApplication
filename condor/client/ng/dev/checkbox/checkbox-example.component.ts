import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';

@Component({
  selector: 'checkbox',
  templateUrl: './checkbox-example.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})

export class CheckboxExampleComponent implements OnInit {
  jurisdictions: Array<any>;
  viewDefault: boolean;
  option1: boolean;
  option2: boolean;
  optionInfo: boolean;
  infoData: string;

  ngOnInit(): void {
    this.viewDefault = false;
    this.jurisdictions = [];
    this.option1 = true;
    this.option2 = false;
    this.optionInfo = false;
    this.infoData = 'info-Data-value';
  }

  onViewDefaultChange(): any {

    if (this.viewDefault) {
      this.jurisdictions.push({
        key: 'ZZZ',
        code: 'ZZZ',
        value: 'jusrisdiction value'
      });
    } else {
      this.jurisdictions = [];
    }
  }

}