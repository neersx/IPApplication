import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import * as _ from 'underscore';
import { ElementBaseComponent } from '../element-base.component';

@Component({
  selector: 'ipx-text-dropdown-group',
  templateUrl: './ipx-text-dropdown-group.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxTextDropdownGroupComponent extends ElementBaseComponent<string> implements OnInit {
  @Input() label: string;
  @Input() options: any;
  @Input() keyField: string;
  @Input() displayField: string;
  @Input() isTextDisabled: boolean;
  @Input() optionalValue: string;
  @Input() textField: string;
  @Input() optionField: string;
  textId: string;
  dropdownId: string;
  option: any;
  textValue: string;
  textdisabled: boolean;
  item: any;
  model: any;
  value: any;
  applyTranslate: boolean;

  ngOnInit(): void {
    this.textId = this.getId('textfield');
    this.dropdownId = this.getId('dropdown');
    this.applyTranslate = this.shouldTranslate();
    this.model = {};
  }
  writeValue = (value: any): void => {
    if (value == null) {
      this.textValue = '';
      this.option = null;
    } else {
      this.textValue = value[this.textField || 'text'];
      this.option = value[this.optionField || 'option'];
      this.model[this.textField || 'text'] = this.textValue;
      this.model[this.optionField || 'option'] = this.option;
      this.setTextField(this.isTextDisabled);
    }
    this.cdr.markForCheck();
  };

  change = (newoption: any): void => {
    this.model[this.optionField || 'option'] = newoption;
    this._onChange(this.model);
  };
  onKeyup = (): void => {
    this.model[this.textField || 'text'] = this.textValue;
    this._onChange(this.model);
    this.setTextField(this.isTextDisabled);
  };
  shouldTranslate(): boolean {
    if (!_.any(this.options)) {
      return false;
    }
    const anyItem = this.displayField ? _.first(this.options)[this.displayField]
      : _.first(this.options);

    return typeof (anyItem) === 'string';
  }

  trackByFn = (index: number, item: any): any => {
    return item;
  };

  setTextField = (isTextDisabled: boolean): void => {
    if (!isTextDisabled) {
      return;
    }
    this.textdisabled = isTextDisabled;
    if (isTextDisabled) {
      this.textValue = '';
    }
  };
}