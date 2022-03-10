import { ChangeDetectionStrategy, Component } from '@angular/core';
import * as _ from 'underscore';

@Component({
  selector: 'dropdown',
  templateUrl: './dropdown-example.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DropdownExampleComponent {
  label: string;
  options1: any = [];
  options2: any = [];
  options3: any = [];
  selectedValue1: any;
  selectedValue2: any;
  selectedValue3: any;
  isDisabled: boolean;
  isRequired: boolean;
  optionalValue: string;
  model1: { text: number; option: string; };
  model2: { text: number; option: string; };
  options: Array<{ name: string; value: string; }>;
  codeChanged: string;
  code: string;

  constructor() {
    this.label = 'DropDown';
    this.isDisabled = false;
    this.isRequired = false;
    this.options1 = [
      {
        key: 3,
        value: 'Attorney Case'
      },
      {
        key: 1035,
        value: 'bikesh appeal'
      },
      {
        key: 22,
        value: 'BikeshAppeal'
      }
    ];

    this.options2 = [{
      key: 20,
      value: 'ritesh Case'
    },
    {
      key: 21,
      value: 'abhishek appeal'
    },
    {
      key: 30,
      value: 'Neeraj'
    }];

    this.options3 = [{
      key: 41,
      value: 'ritesh Case'
    },
    {
      key: 412,
      value: 'abhishesk appeal'
    },
    {
      key: 43,
      value: 'Neeraj'
    }];

    this.selectedValue1 = _.last(this.options1);
    this.selectedValue2 = _.last(this.options2);
    this.selectedValue3 = '';
    this.optionalValue = 'select';

    this.model1 = {
      text: 1,
      option: 'v1'
    };
    this.model2 = {
      text: 2,
      option: 'v2'
    };
    this.options = [{
      name: 'n1',
      value: 'v1'
    }, {
      name: 'n2',
      value: 'v2'
    }];
  }
}
