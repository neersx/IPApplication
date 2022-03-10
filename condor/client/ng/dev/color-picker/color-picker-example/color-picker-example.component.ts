import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { PaletteSettings } from '@progress/kendo-angular-inputs';
import { ColorPickerFormatEnum } from 'shared/component/forms/ipx-color-picker/ipx-color-picker.component';

@Component({
  selector: 'color-picker-example',
  templateUrl: './color-picker-example.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ColorPickerExampleComponent implements OnInit {

  color = '#f9d9ab';
  value = '#ffffff';
  customRgb = '';
  isDisabled: boolean;
  settings: PaletteSettings;
  formatRgb = ColorPickerFormatEnum.Rgba;

  ngOnInit(): void {
    this.settings = {
      palette: [
        '#f0d0c9', '#e2a293', '#d4735e', '#65281a',
        '#a0eef5', '#93d8ef'
      ],
      tileSize: 30,
      columns: 4
    };
  }
}
