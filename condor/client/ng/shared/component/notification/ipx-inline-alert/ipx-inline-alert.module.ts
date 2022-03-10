import { NgModule } from '@angular/core';
import { BaseCommonModule } from 'shared/base.common.module';
import { IpxInlineAlertComponent } from './ipx-inline-alert.component';

@NgModule({
  imports: [BaseCommonModule],
  providers: [],
  declarations: [IpxInlineAlertComponent],
  exports: [IpxInlineAlertComponent]
})
export class IpxInlineAlertModule {}
