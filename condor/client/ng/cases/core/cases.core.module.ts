import { NgModule } from '@angular/core';
import { AttachmentsPopupComponent } from 'common/attachments/attachments-popup/attachments-popup.component';
import { PopoverModule } from 'ngx-bootstrap/popover';
import { TooltipModule } from 'ngx-bootstrap/tooltip';
import { BaseCommonModule } from 'shared/base.common.module';
import { ButtonsModule } from 'shared/component/buttons/buttons.module';
import { PipesModule } from 'shared/pipes/pipes.module';
import { CaseNavigationService } from './case-navigation.service';
import { IpxDueDateComponent } from './ipx-due-date.component';

@NgModule({
   imports: [
      PopoverModule,
      BaseCommonModule,
      TooltipModule,
      PipesModule,
      ButtonsModule
   ],
   exports: [
      IpxDueDateComponent,
      AttachmentsPopupComponent
   ],
   declarations: [
      IpxDueDateComponent,
      AttachmentsPopupComponent
   ],
   providers: [
      CaseNavigationService
   ]
})
export class CasesCoreModule { }
