import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { SharedModule } from 'shared/shared.module';
import { TaxCodeComponent } from './tax-code-component';
import { TaxCodeDetailsComponent } from './tax-code-details.component';
import { TaxCodeMaintenanceComponent } from './tax-code-maintenance.component';
import { taxCodeDetailState, taxCodeState } from './tax-code-routing.states';
import { TaxCodeOverviewComponent } from './tax-code-topics/tax-code-overview.component';
import { TaxCodeRatesComponent } from './tax-code-topics/tax-code-rates.component';
import { TaxCodeService } from './tax-code.service';

export let routeStates = [taxCodeState, taxCodeDetailState];

@NgModule({
    imports: [
        SharedModule,
        UIRouterModule.forChild({ states: routeStates })
    ],
    declarations: [TaxCodeComponent, TaxCodeMaintenanceComponent, TaxCodeDetailsComponent, TaxCodeOverviewComponent, TaxCodeRatesComponent],
    providers: [TaxCodeService],
    exports: [TaxCodeComponent],
    entryComponents: [TaxCodeMaintenanceComponent]
})
export class TaxCodeModule { }
