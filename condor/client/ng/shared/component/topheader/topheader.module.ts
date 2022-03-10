import { CommonModule } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslateModule } from '@ngx-translate/core';
import { TimeRecordingWidgetModule } from 'accounting/time-recording-widget/time-recording-widget.module';
import { PopoverModule } from 'ngx-bootstrap/popover';
import { TooltipModule as NgxTooltipModule } from 'ngx-bootstrap/tooltip';
import { ButtonsModule } from '../buttons/buttons.module';
import { IpxIeOnlyUrlModule } from '../forms/ipx-ie-only-url/ipx-ie-only-url.module';
import { QuickSearchModule } from '../quicksearch/quick-search.module';
import { TooltipModule } from '../tooltip/tooltip.module';
import { TopHeaderComponent } from './ipx-top-header.component';

@NgModule({
  declarations: [
    TopHeaderComponent
  ],
  imports: [
    CommonModule,
    NgxTooltipModule,
    TooltipModule,
    PopoverModule,
    HttpClientModule,
    FormsModule,
    ButtonsModule,
    IpxIeOnlyUrlModule,
    TranslateModule,
    QuickSearchModule,
    TimeRecordingWidgetModule
  ],
  exports: [
    TopHeaderComponent
  ]
})
export class TopHeaderModule {}
