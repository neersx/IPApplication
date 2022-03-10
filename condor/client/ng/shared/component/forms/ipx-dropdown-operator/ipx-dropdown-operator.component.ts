import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Input, OnInit, Optional, Renderer2, Self, ViewChild } from '@angular/core';
import { NgControl } from '@angular/forms';
import { ElementBaseComponent } from '../element-base.component';

@Component({
  selector: 'ipx-dropdown-operator',
  templateUrl: './ipx-dropdown-operator.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxDropdownOperatorComponent extends ElementBaseComponent implements OnInit {
  @Input() label: string;
  @Input() operatorsGroup: any;
  @Input() customOperators: any;
  @Input() value: any;
  @ViewChild('selectoperatorref', { static: true }) select: ElementRef;

  operatorOptions: any;
  options: any;
  dateOptions: any;
  optionsCombinations: any;
  isDropdownValueChanged: boolean;
  item: any;
  identifier: string;

  constructor(private readonly renderer: Renderer2, @Self() @Optional() public control: NgControl, public el: ElementRef, cdr: ChangeDetectorRef) {
    super(control, el, cdr);
    this.initializeField();
  }

  change = (newValue): void => {
    this.value = newValue;
    this._onChange(this.value);
    this.onChange.emit(this.value);
  };

  ngOnInit(): void {
    this.identifier = this.getId('dropdownoperator');

    this.operatorOptions = [];
    if (this.operatorsGroup !== undefined) {
      this.operatorOptions = this.optionsCombinations[this.operatorsGroup] || this.optionsCombinations.Equal;
    }
    if (this.customOperators !== undefined) {
      const operatorsArray = this.customOperators.split(',');
      for (const operator of operatorsArray) {
        if (this.options[operator]) {
          this.operatorOptions.push(this.options[operator]);
        }
      }
    }
  }
  setDisabledState(isDisabled: boolean): void {
    if (this.select) {
      isDisabled ? this.renderer.setAttribute(this.select.nativeElement, 'disabled', 'disabled') : this.renderer.removeAttribute(this.select.nativeElement, 'disabled');
    }
  }

  initializeField(): void {
    this.options = {
      equalTo: { key: '0', value: 'operators.equalTo' },
      notEqualTo: { key: '1', value: 'operators.notEqualTo' },
      startsWith: { key: '2', value: 'operators.startsWith' },
      endsWith: { key: '3', value: 'operators.endsWith' },
      contains: { key: '4', value: 'operators.contains' },
      exists: { key: '5', value: 'operators.exists' },
      notExists: { key: '6', value: 'operators.notExists' },
      between: { key: '7', value: 'operators.between' },
      notBetween: { key: '8', value: 'operators.notBetween' },
      soundsLike: { key: '9', value: 'operators.soundsLike' },
      lessThan: { key: '10', value: 'operators.lessThan' },
      lessEqual: { key: '11', value: 'operators.lessEqual' },
      greater: { key: '12', value: 'operators.greater' },
      greaterEqual: { key: '13', value: 'operators.greaterEqual' },
      sinceLastWorkDay: { key: '14', value: 'operators.sinceLastWorkDay' }
    };

    this.dateOptions = {
      withinLast: { key: 'L', value: 'operators.withinLast' },
      withinNext: { key: 'N', value: 'operators.withinNext' },
      specificDate: { key: 'sd', value: 'operators.SpecificDates' }
    };

    this.optionsCombinations = {
      Full: [this.options.equalTo, this.options.notEqualTo, this.options.startsWith, this.options.endsWith, this.options.contains, this.options.exists, this.options.notExists],
      FullSoundsLike: [this.options.equalTo, this.options.notEqualTo, this.options.startsWith, this.options.endsWith, this.options.contains, this.options.exists, this.options.notExists, this.options.soundsLike],
      FullNoExist: [this.options.equalTo, this.options.notEqualTo, this.options.startsWith, this.options.endsWith, this.options.contains],
      Equal: [this.options.equalTo, this.options.notEqualTo],
      Between: [this.options.between, this.options.notBetween],
      BetweenWithLastWorkDay: [this.options.between, this.options.notBetween, this.options.sinceLastWorkDay],
      EqualExist: [this.options.equalTo, this.options.notEqualTo, this.options.exists, this.options.notExists],
      StartEndExist: [this.options.startsWith, this.options.endsWith, this.options.exists, this.options.notExists],
      DatesFull: [this.options.equalTo, this.options.notEqualTo, this.options.lessThan, this.options.lessEqual, this.options.greater, this.options.greaterEqual, this.options.exists, this.options.notExists, this.dateOptions.withinLast, this.dateOptions.withinNext, this.dateOptions.specificDate]
    };
  }
}
