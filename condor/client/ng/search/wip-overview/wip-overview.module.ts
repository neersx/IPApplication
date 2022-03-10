import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { CasesCoreModule } from 'cases/core/cases.core.module';
import { DatesModule } from 'dates/dates.module';
import { SharedModule } from 'shared/shared.module';
import { CreateBillsModalComponent } from './create-bills-modal/create-bills-modal.component';
import { WipOverviewProvider } from './wip-overview.provider';
import { WipOverviewService } from './wip-overview.service';
@NgModule({
  imports: [
    CommonModule,
    UIRouterModule.forChild({ states: [] }),
    SharedModule,
    CasesCoreModule,
    DatesModule
  ],
  declarations: [
    CreateBillsModalComponent
  ],
  providers: [WipOverviewService, WipOverviewProvider],
  entryComponents: []
})
export class WipOverviewModule { }