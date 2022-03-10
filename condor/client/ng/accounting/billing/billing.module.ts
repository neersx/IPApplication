import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { UIRouterModule } from '@uirouter/angular';
import { CoreModule } from 'core/core.module';
import { LocalCurrencyFormatPipe } from 'shared/pipes/local-currency-format.pipe';
import { SharedModule } from './../../shared/shared.module';
import { BillingHeaderComponent } from './billing-header/billing-header.component';
import { BillingReferencesComponent } from './billing-maintenance/billing-references/billing-references.component';
import { CaseDebtorComponent } from './billing-maintenance/case-debtor/case-debtor.component';
import { CaseDebtorService } from './billing-maintenance/case-debtor/case-debtor.service';
import { AddDebtorsComponent } from './billing-maintenance/case-debtor/debtors/add-debtors/add-debtors.component';
import { DebtorCopiesToNamesGridComponent } from './billing-maintenance/case-debtor/debtors/debtor-details/debtor-copies-to/debtor-copies-to-grid.component';
import { DebtorCopiesToComponent } from './billing-maintenance/case-debtor/debtors/debtor-details/debtor-copies-to/debtor-copies-to.component';
import { MaintainDebtorCopiesToComponent } from './billing-maintenance/case-debtor/debtors/debtor-details/debtor-copies-to/maintain-debtor-copies-to.component';
import { DebtorInstructionsComponent } from './billing-maintenance/case-debtor/debtors/debtor-details/debtor-instructions.component';
import { DebtorWarningsComponent } from './billing-maintenance/case-debtor/debtors/debtor-details/debtor-warnings.component';
import { DebtorDiscountComponent } from './billing-maintenance/case-debtor/debtors/debtor-discount/debtor-discount.component';
import { DebtorsComponent } from './billing-maintenance/case-debtor/debtors/debtors.component';
import { CaseStatusRestrictionComponent } from './billing-maintenance/case-debtor/maintain-case-debtor/case-status-restriction.component';
import { MaintainCaseDebtorComponent } from './billing-maintenance/case-debtor/maintain-case-debtor/maintain-case-debtor.component';
import { UnpostedTimeListComponent } from './billing-maintenance/case-debtor/unposted-time-list/unposted-time-list.component';
import { MaintainBilledAmountComponent } from './billing-maintenance/wip-selection/maintain-billed-amount.component';
import { WipSelectionComponent } from './billing-maintenance/wip-selection/wip-selection.component';
import { WipSelectionService } from './billing-maintenance/wip-selection/wip-selection.service';
import { BillingService } from './billing-service';
import { BillingStepsPersistanceService } from './billing-steps-persistance.service';
import { BillingWizardMultistepComponent } from './billing-wizard-multistep/billing-wizard-multistep.component';
import { BillingComponent } from './billing.component';
import { CreateSingleBill, DebitNoteState } from './billing.states';

export let routeStates = [DebitNoteState, CreateSingleBill];

@NgModule({
    declarations: [
        BillingComponent,
        BillingWizardMultistepComponent,
        BillingHeaderComponent,
        CaseDebtorComponent,
        MaintainCaseDebtorComponent,
        UnpostedTimeListComponent,
        CaseStatusRestrictionComponent,
        DebtorsComponent,
        DebtorWarningsComponent,
        DebtorInstructionsComponent,
        AddDebtorsComponent,
        DebtorDiscountComponent,
        DebtorCopiesToComponent,
        DebtorCopiesToNamesGridComponent,
        MaintainDebtorCopiesToComponent,
        BillingReferencesComponent,
        WipSelectionComponent,
        MaintainBilledAmountComponent],
    imports: [
        CommonModule,
        UIRouterModule,
        SharedModule,
        FormsModule,
        ReactiveFormsModule,
        UIRouterModule.forChild({ states: routeStates }),
        CoreModule
    ],
    exports: [LocalCurrencyFormatPipe],
    entryComponents: [BillingComponent, MaintainCaseDebtorComponent, DebtorDiscountComponent],
    providers: [BillingService, CaseDebtorService, BillingStepsPersistanceService, WipSelectionService]
})
export class BillingModule { }
