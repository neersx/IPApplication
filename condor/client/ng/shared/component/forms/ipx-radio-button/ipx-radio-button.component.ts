import { ChangeDetectionStrategy, Component, EventEmitter, HostBinding, Input, OnInit, Output, ViewChild } from '@angular/core';
import { ElementBaseComponent } from '../../forms/element-base.component';

export interface IChangeRadioEventArgs {
  value: any;
  radio: IpxRadioButtonComponent;
}

@Component({
  selector: 'ipx-radio-button',
  templateUrl: './ipx-radio-button.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxRadioButtonComponent extends ElementBaseComponent implements OnInit {

  @Input() label: string;

  @HostBinding('attr.id') id: string;
  @Input() value: any;
  @Input() name: string;
  @Output() readonly changeRadio: EventEmitter<IChangeRadioEventArgs> = new EventEmitter<IChangeRadioEventArgs>();
  @Input() checked = false;

  inputId: string;
  model: any;

  ngOnInit(): void {
    const id = this.el.nativeElement.attributes.id;
    this.id = !id ? `ipx-radio-${this.getId()}` : id.value;

    this.inputId = `${this.id}-input`;
  }

  _onRadioClick(event): any {
    event.stopPropagation();
    this.select();
  }

  select(): any {
    if (this.disabled) {
      return;
    }

    this.checked = true;
    this._onChange(this.value);
    this.changeRadio.emit({ value: this.value, radio: this });
    this._onTouch();
  }

  writeValue = (value: any): void => {
    this.checked = (value === this.value);
    this.cdr.markForCheck();
  };
}
