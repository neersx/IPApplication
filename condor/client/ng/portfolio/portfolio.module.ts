import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { CoreModule } from 'core/core.module';
import { DatesModule } from 'dates/dates.module';
import { FormControlsModule } from 'shared/component/forms/form-controls.module';
import { TooltipModule } from 'shared/component/tooltip/tooltip.module';
import { CaseValidateCharacteristicsCombinationService } from './case/case-validate-characteristics-combination.service';
import { DebtorRestrictionFlagComponent } from './debtor-restriction-flag/debtor-restriction-flag.component';
import { DebtorRestrictionsService } from './debtor-restriction-flag/debtor-restriction.service';
import { DisplayableNameTypeFieldsHelper } from './names/displayable-fields';
import { NameDetailsComponent } from './names/name-details.component';
import { NameDetailsService } from './names/name-details.service';

const components = [
  DebtorRestrictionFlagComponent,
  NameDetailsComponent
];

@NgModule({
  declarations: [
    ...components
  ],
  imports: [
    CommonModule,
    CoreModule,
    TooltipModule,
    FormControlsModule
  ],
  providers: [
    DebtorRestrictionsService,
    DisplayableNameTypeFieldsHelper,
    NameDetailsService,
    CaseValidateCharacteristicsCombinationService
  ],
  exports: [
    ...components
  ]
})
export class PortfolioModule { }
