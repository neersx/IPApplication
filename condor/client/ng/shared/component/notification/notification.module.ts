import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslateModule } from '@ngx-translate/core';
import { BaseCommonModule } from 'shared/base.common.module';
import { ButtonsModule } from '../buttons/buttons.module';
import { FormControlsModule } from '../forms/form-controls.module';
import { IpxInfoComponent } from './ipx-info/ipx-info.component';
import { IpxInlineAlertModule } from './ipx-inline-alert/ipx-inline-alert.module';
import { IpxNotificationComponent } from './notification/ipx-notification.component';
import { IpxNotificationService } from './notification/ipx-notification.service';

@NgModule({
  imports: [BaseCommonModule, ButtonsModule, FormControlsModule, FormsModule, TranslateModule],
  exports: [IpxInlineAlertModule, IpxInfoComponent],
  declarations: [IpxNotificationComponent, IpxInfoComponent],
  providers: [IpxNotificationService],
  entryComponents: [IpxNotificationComponent, IpxInfoComponent]
})
export class NotificationModule { }
