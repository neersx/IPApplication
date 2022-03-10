import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Input, OnInit, Optional, Renderer2, Self, ViewChild } from '@angular/core';
import { NgControl } from '@angular/forms';
import { BehaviorSubject } from 'rxjs';
import * as  _ from 'underscore';
import { ElementBaseComponent } from '../element-base.component';

@Component({
  selector: 'ipx-dropdown',
  templateUrl: './ipx-dropdown.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxDropdownComponent extends ElementBaseComponent implements OnInit {
  @Input() label: string;
  @Input() labelValue: string;
  @Input() set options(values: Array<any>) {
    this._options = values;
  }
  @Input() keyField: string;
  @Input() displayField: string;
  @Input() optionalValue: string;
  @Input() removeOptionalValue: boolean;
  @ViewChild('selectref', { static: true }) select: ElementRef;
  showError$ = new BehaviorSubject(false);

  isOptional: boolean;
  identifier: string;
  applyTranslate: boolean;
  _options = [];

  constructor(private readonly renderer: Renderer2, @Self() @Optional() public control: NgControl, public el: ElementRef, cdr: ChangeDetectorRef) {
    super(control, el, cdr);
  }

  ngOnInit(): void {
    this.identifier = this.getId('dropdown');
    this.applyTranslate = this.shouldTranslate();
    this.isOptional = this.el.nativeElement.hasAttribute('required') ? false : !this.removeOptionalValue; // === true ? true : false; getAttribute gave empty string when the attribute is there.
    // moved the below logic from @input's set, as the order in which the ngOninit and @Input prop's are called is not always only after ngOninit is called & can vary interchangeably.
    if (this._options && this._options.length > 0) {
      this._resetInvalidSeletion(this._options);
    }

    if (this.control && this.control.control) {
      if (this.control.control.dirty) {
        this.updatecontrolState();
      }
      this.control.control.statusChanges.subscribe((value) => {
        if (value) {
          this.updatecontrolState();
        }
      });
    }
  }

  updatecontrolState = () => {
    this.showError$.next(this.showError());
  };

  shouldTranslate(): boolean {
    if (!_.any(this._options)) {
      return false;
    }

    const anyItem = this.displayField ? _.first(this._options)[this.displayField]
      : _.first(this._options);

    return typeof (anyItem) === 'string';
  }
  setDisabledState(isDisabled: boolean): void {
    isDisabled ? this.renderer.setAttribute(this.select.nativeElement, 'disabled', 'disabled') : this.renderer.removeAttribute(this.select.nativeElement, 'disabled');
  }
  change = (newValue: any): void => {
    this.value = newValue;
    this._onChange(this.value);
    this.onChange.emit(this.value);
  };

  trackByFn = (index: number, item: any): any => {
    return item;
  };

  writeValue = (value: any) => {
    if (typeof (value) === 'string' || typeof (value) === 'number') {
      this.value = value;
    } else if (value && this.displayField) {
      const val = _.filter(this._options, (option) => {
        return option[this.displayField] === value[this.displayField];
      });
      this.value = _.first(val);
    } else {
      this.value = value;
    }
  };

  _resetInvalidSeletion = (options: Array<any>) => {
    // the below code was modified for more checks, because in cases where the ngModel value is a number/string(not an obj), key & displayField are also given, then it was making the value to null.
    if (this.value) {
      if (typeof (this.value) === 'string' || typeof (this.value) === 'number') {
        if (this.keyField) {
          if (options.filter(v => v[this.keyField] === this.value).length === 0) {
            this.value = null;
          }
        } else if (options.filter(v => v === this.value).length === 0) {
          this.value = null;
        }
      } else if (this.displayField) {
        if (options.filter(v => v[this.displayField] === this.value[this.displayField]).length === 0) {
          this.value = null;
        }
      }
    }
  };
}
