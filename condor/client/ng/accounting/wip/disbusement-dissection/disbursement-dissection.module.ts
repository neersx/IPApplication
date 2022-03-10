import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { UIRouterModule } from '@uirouter/angular';
import { WarningService } from 'accounting/warnings/warning-service';
import { CasenamesWarningsComponent, NameOnlyWarningsComponent, WarningsModule } from 'accounting/warnings/warnings.module';
import { CoreModule } from 'core/core.module';
import { LocalCurrencyFormatPipe } from 'shared/pipes/local-currency-format.pipe';
import { PipesModule } from 'shared/pipes/pipes.module';
import { SharedModule } from 'shared/shared.module';
import { DisbursementDissectionState } from './disbursement-dissection-routing.states';
import { DisbursementDissectionWipComponent } from './disbursement-dissection-wip/disbursement-dissection-wip.component';
import { DisbursementDissectionComponent } from './disbursement-dissection.component';
import { DisbursementDissectionService } from './disbursement-dissection.service';

export let routeStates = [DisbursementDissectionState];

@NgModule({
    declarations: [
        DisbursementDissectionComponent,
        DisbursementDissectionWipComponent
    ],
    imports: [
        CommonModule,
        RouterModule,
        UIRouterModule.forChild({ states: routeStates }),
        FormsModule,
        ReactiveFormsModule,
        SharedModule,
        CoreModule,
        PipesModule,
        WarningsModule
    ],
    providers: [
        WarningService,
        DisbursementDissectionService
    ],
    entryComponents: [
        DisbursementDissectionComponent,
        CasenamesWarningsComponent,
        NameOnlyWarningsComponent
    ],
    exports: [LocalCurrencyFormatPipe]
})
export class DisbursementDissectionModule {
}
