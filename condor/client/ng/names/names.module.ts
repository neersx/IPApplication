import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { FormControlsModule } from 'shared/component/forms/form-controls.module';
import { NotificationModule } from 'shared/component/notification/notification.module';
import { NamesSummaryPaneComponent } from './names-summary-pane/names-summary-pane.component';
import { NamesSummaryPaneService } from './names-summary-pane/names-summary-pane.service';

import { PortfolioModule } from 'portfolio/portfolio.module';
import { BaseCommonModule } from 'shared/base.common.module';

const components = [
  NamesSummaryPaneComponent
];
@NgModule({
   declarations: [
      ...components
   ],
   providers: [
      NamesSummaryPaneService
   ],
   imports: [
      CommonModule,
      NotificationModule,
      FormControlsModule,
      BaseCommonModule,
      PortfolioModule
   ],
   exports: [
      ...components
   ]
})
export class NamesModule { }
