import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { TranslateModule } from '@ngx-translate/core';
import { IpxWidgetFrameComponent } from './ipx-widget-frame/ipx-widget-frame.component';

@NgModule({
  declarations: [IpxWidgetFrameComponent],
  imports: [
    CommonModule,
    TranslateModule,
    CommonModule
  ],
  exports: [IpxWidgetFrameComponent]
})
export class WidgetModule { }
