// tslint:disable:template-use-track-by-function
import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { FormBuilder, FormControl } from '@angular/forms';
import * as _ from 'underscore';

class RadioOption {
  favoriteOption: string;

  constructor(public name: string, option?: string) {
    if (option) {
      this.favoriteOption = option;
    }
  }
}

@Component({
  selector: 'radiobutton-example',
  templateUrl: './radiobutton-example.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class RadiobuttonExampleComponent implements OnInit {
  formData: any;
  radio1: boolean;
  selectedValue: any;
  item: any;
  userPreference: string;
  errorMessage: any;
  appsDisabled: boolean;
  changeUserPreferenceDebounce: () => void;
  userPref: FormControl;
  selectedPref: string;

  options = [
    'Option1',
    'Option2',
    'Option3',
    'Option4'
  ];

  optionResult: RadioOption = new RadioOption('Inprotech', this.options[2]);

  constructor(formbuilder: FormBuilder) {
    this.changeUserPreferenceDebounce = _.debounce(this.performUserPreferenceChange, 1000);
    this.userPref = formbuilder.control('app');
  }

  ngOnInit(): void {
    this.radio1 = true;
    this.formData = {
      type: '0'
    };
  }

  get diagnostic(): any {
    return JSON.stringify(this.optionResult);
  }

  performUserPreferenceChange = () => {
    this.selectedPref = this.userPref.value;
  };

  onRadioChange(evt): any {
    this.selectedValue = evt.target.attributes['ng-reflect-value'].value;
  }

}