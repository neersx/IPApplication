// tslint:disable: prefer-inline-decorator
import { AfterContentInit, ChangeDetectionStrategy, Component, ContentChildren, EventEmitter, Input, OnDestroy, Output, QueryList } from '@angular/core';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { ElementBaseComponent } from '../element-base.component';
import { IChangeRadioEventArgs, IpxRadioButtonComponent } from '../ipx-radio-button/ipx-radio-button.component';

let nextId = 0;

@Component({
  selector: 'ipx-radio-button-group',
  template: '<ng-content></ng-content>',
  changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxRadioButtonGroupComponent extends ElementBaseComponent implements AfterContentInit, OnDestroy {

  @ContentChildren(IpxRadioButtonComponent) radioButtons: QueryList<IpxRadioButtonComponent>;

  @Input()
  get value(): any { return this._value; }
  set value(newValue: any) {
    if (this._value !== newValue) {
      this._value = newValue;
      this._selectRadioButton();
    }
  }

  @Input()
  get name(): string { return this._name; }
  set name(newValue: string) {
    if (this._name !== newValue) {
      this._name = newValue;
      this._setRadioButtonNames();
    }
  }

  @Input()
  get disabled(): boolean { return this._disabled; }
  set disabled(newValue: boolean) {
    if (this._disabled !== newValue) {
      this._disabled = newValue;
      this._disableRadioButtons();
    }
  }

  @Input()
  get selected(): IpxRadioButtonComponent { return this._selected; }
  set selected(selected: IpxRadioButtonComponent | null) {
    if (this._selected !== selected) {
      this._selected = selected;
      this.value = selected ? selected.value : null;
    }
  }

  @Output() readonly changeRadioGrp: EventEmitter<IChangeRadioEventArgs> = new EventEmitter<IChangeRadioEventArgs>();

  private _name = `ipx-radio-group-${nextId++}`;
  private _value: any = null;
  private _selected: IpxRadioButtonComponent | null = null;
  private _isInitialized = false;
  private _disabled = false;
  private readonly destroy$ = new Subject<boolean>();

  ngAfterContentInit(): void {
    this._isInitialized = true;
    setTimeout(() => { this._initRadioButtons(); });
  }

  ngOnDestroy(): void {
    this.destroy$.next(true);
    this.destroy$.complete();
  }

  private _initRadioButtons(): any {
    if (this.radioButtons) {
      this.radioButtons.forEach((button) => {
        button.name = this._name;

        if (this._value && button.value === this._value) {
          button.checked = true;
          this._selected = button;
        }
        button.cdr.detectChanges();
        button.changeRadio.pipe(takeUntil(this.destroy$)).subscribe((ev) => this._selectedRadioButtonChanged(ev));
      });
    }
  }

  private _selectedRadioButtonChanged(args: IChangeRadioEventArgs): any {
    if (this._selected !== args.radio) {
      if (this._selected) {
        this._selected.checked = false;
        this._selected.cdr.detectChanges();
      }
      this._selected = args.radio;
    }

    this._value = args.value;

    if (this._isInitialized) {
      this.changeRadioGrp.emit(args);
      this._onChange(this.value);
    }
  }

  private _setRadioButtonNames(): void {
    if (this.radioButtons) {
      this.radioButtons.forEach((button) => {
        button.name = this._name;
        button.cdr.markForCheck();
      });
    }
  }

  private _selectRadioButton(): void {
    if (this.radioButtons) {
      this.radioButtons.forEach((button) => {
        if (!this._value) {
          // no value - uncheck all radio buttons
          if (button.checked) {
            button.checked = false;
          }
        } else {
          if (this._value === button.value) {
            // selected button
            if (this._selected !== button) {
              this._selected = button;
            }

            if (!button.checked) {
              button.select();
            }
          } else {
            // non-selected button
            if (button.checked) {
              button.checked = false;
            }
          }
          button.cdr.markForCheck();
        }
      });
    }
  }

  private _disableRadioButtons(): void {
    if (this.radioButtons) {
      this.radioButtons.forEach((button) => {
        button.disabled = this._disabled;
        button.cdr.markForCheck();
      });
    }
  }

}
