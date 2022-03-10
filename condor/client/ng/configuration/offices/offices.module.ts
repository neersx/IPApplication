import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { ButtonsModule } from 'shared/component/buttons/buttons.module';
import { SharedModule } from 'shared/shared.module';
import { OfficeMaintenanceComponent } from './office-maintenance/office-maintenance.component';
import { offices } from './office-states';
import { OfficeComponent } from './offices.component';
import { OfficeService } from './offices.service';

@NgModule({
    declarations: [
        OfficeComponent,
        OfficeMaintenanceComponent
    ],
    imports: [
        SharedModule,
        ButtonsModule,
        UIRouterModule.forChild({ states: [offices] })
    ],
    providers: [
        OfficeService
    ],
    exports: [
    ],
    entryComponents: [OfficeComponent, OfficeMaintenanceComponent]
})
export class OfficeModule { }