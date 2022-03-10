import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { UIRouterModule } from '@uirouter/angular';
import { FormControlsModule } from 'shared/component/forms/form-controls.module';
import { SharedModule } from 'shared/shared.module';
import { sanityCheckConfigurationMaintenanceEditState, sanityCheckConfigurationMaintenanceInsertState, sanityCheckConfigurationState } from './sanity-check-configuration-states';
import { SanityCheckConfigurationComponent } from './sanity-check-configuration.component';
import { SanityCheckConfigurationService } from './sanity-check-configuration.service';
import { SanityCheckRuleCaseCharacteristicsComponent } from './sanity-check-maintenance/case-characteristics/case-characteristics.component';
import { SanityCheckRuleCaseNameComponent } from './sanity-check-maintenance/case-name/case-name.component';
import { SanityCheckRuleEventComponent } from './sanity-check-maintenance/event/event.component';
import { SanityCheckRuleNameCharacteristicsComponent } from './sanity-check-maintenance/name-characteristics/name-characteristics.component';
import { SanityCheckRuleOtherComponent } from './sanity-check-maintenance/other/other.component';
import { SanityCheckRuleOverviewComponent } from './sanity-check-maintenance/rule-overview/rule-overview.component';
import { SanityCheckConfigurationMaintenanceComponent } from './sanity-check-maintenance/sanity-check-maintenance.component';
import { SanityCheckMaintenanceService } from './sanity-check-maintenance/sanity-check-maintenance.service';
import { SanityCheckRuleStandingInstructionComponent } from './sanity-check-maintenance/standing-instruction/standing-instruction.component';
import { SearchByCaseComponent } from './search-by-case/search-by-case.component';
import { SearchByNameComponent } from './search-by-name/search-by-name.component';

const topics = [SanityCheckRuleOverviewComponent, SanityCheckRuleCaseCharacteristicsComponent, SanityCheckRuleCaseNameComponent, SanityCheckRuleStandingInstructionComponent , SanityCheckRuleEventComponent, SanityCheckRuleOtherComponent, SanityCheckRuleNameCharacteristicsComponent];
@NgModule({
  imports: [
    SharedModule,
    FormsModule,
    FormControlsModule,
    UIRouterModule.forChild({ states: [sanityCheckConfigurationState, sanityCheckConfigurationMaintenanceInsertState, sanityCheckConfigurationMaintenanceEditState] })
  ],
  declarations: [SanityCheckConfigurationComponent, SearchByCaseComponent, SearchByNameComponent, SanityCheckConfigurationMaintenanceComponent, ...topics],
  entryComponents: [SanityCheckConfigurationComponent, ...topics],
  providers: [SanityCheckConfigurationService, SanityCheckMaintenanceService]
})
export class SanityCheckConfigurationModule { }
