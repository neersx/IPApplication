import { NgModule } from '@angular/core';
import { AttachmentsModule } from './attachments/attachments.module';
import { CaselistModule } from './caselist/caselist.module';
import { CurrenciesModule } from './currencies/currencies.module';
import { DmsIntegrationhModule } from './dms-integration/dms-integration.module';
import { ExchangeRateScheduleModule } from './exchange-rate-schedule/exchange-rate-schedule.module';
import { FileLocationOfficeModule } from './file-location-office/file-location-office.module';
import { KeywordsModule } from './keywords/keywords.module';
import { KeepOnTopNotesModule } from './kot-text-types/kot-text-types.module';
import { OfficeModule } from './offices/offices.module';
import { RecordalTypeModule } from './recordal-type/recordal-type.module';
import { ReportingServicesIntegrationModule } from './reporting-services-integration/reporting-services-integration.module';
import { RulesModule } from './rules/rules.module';
import { SanityCheckConfigurationModule } from './sanity-check/sanity-check-configuration.module';
import { TaskPlannerConfigurationModule } from './task-planner-configuration/task-planner-configuration.module';
import { TaxCodeModule } from './tax-code/tax-code.module';

@NgModule({
   imports: [
      DmsIntegrationhModule,
      RulesModule,
      ReportingServicesIntegrationModule,
      CaselistModule,
      AttachmentsModule,
      KeepOnTopNotesModule,
      RecordalTypeModule,
      OfficeModule,
      CurrenciesModule,
      ExchangeRateScheduleModule,
      KeywordsModule,
      FileLocationOfficeModule,
      TaskPlannerConfigurationModule,
      SanityCheckConfigurationModule,
      TaxCodeModule
   ],
   exports: [
      DmsIntegrationhModule,
      RulesModule,
      ReportingServicesIntegrationModule,
      CaselistModule,
      AttachmentsModule,
      KeepOnTopNotesModule,
      RecordalTypeModule,
      OfficeModule,
      CurrenciesModule,
      ExchangeRateScheduleModule,
      KeywordsModule,
      FileLocationOfficeModule,
      TaxCodeModule
   ]
})
export class ConfigurationModule { }
