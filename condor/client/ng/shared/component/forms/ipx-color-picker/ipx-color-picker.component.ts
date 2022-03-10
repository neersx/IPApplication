import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { PaletteSettings } from '@progress/kendo-angular-inputs';
import { ElementBaseComponent } from '../element-base.component';

@Component({
  selector: 'ipx-color-picker',
  templateUrl: './ipx-color-picker.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxColorPickerComponent extends ElementBaseComponent<string> implements OnInit {

  @Input() view = ColorPickerViewEnum.Palette;
  @Input() format = ColorPickerFormatEnum.Hex;
  @Input() label: string;
  @Input() settings: PaletteSettings;

  ngOnInit(): void {
    if (!this.settings) {
      this.settings = {
        palette: [
          null, '#fff2ac', '#fae71d', '#ffb171',
          '#ffcce5', '#ceb5e5', '#e5e5e5', '#cdeaff',
          '#cbf1c5', '#b9d87b', '#e3c0b4', '#fd6963'
        ],
        columns: 6,
        tileSize: 30
      };
    }
    this.cdr.markForCheck();
  }

  writeValue = (value: string) => {
    this.value = value;
    this.cdr.detectChanges();
  };

  change = (newValue): void => {
    this.value = newValue;
    this._onChange(this.value);
    this.onChange.emit(this.value);
    this.cdr.detectChanges();
  };
}

export enum ColorPickerViewEnum {
  Palette = 'palette',
  Gradient = 'gradient'
}

export enum ColorPickerFormatEnum {
  Hex = 'hex',
  Rgba = 'rgba'
}