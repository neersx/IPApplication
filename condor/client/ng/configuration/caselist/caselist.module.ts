import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { SharedModule } from 'shared/shared.module';
import { CaselistMaintenanceService } from './caselist-maintenance.service';
import { CaselistMaintenanceComponent } from './caselist-maintenance/caselist-maintenance.component';
import { CaselistModalComponent } from './caselist-modal/caselist-modal.component';
import { caselistMaintenanceState } from './caselist-states';

@NgModule({
  imports: [
    SharedModule,
    UIRouterModule.forChild({ states: [caselistMaintenanceState] })
  ],
  providers: [
    CaselistMaintenanceService
  ],
  declarations: [CaselistMaintenanceComponent, CaselistModalComponent],
  entryComponents: [CaselistMaintenanceComponent]
})
export class CaselistModule { }
