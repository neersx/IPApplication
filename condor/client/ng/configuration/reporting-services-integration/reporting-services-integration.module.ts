import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { ButtonsModule } from 'shared/component/buttons/buttons.module';
import { SharedModule } from 'shared/shared.module';
import { reportingServicesIntegrationState } from './reporting-services-integration-states';
import { ReportingIntegrationSettingsService } from './reporting-services-integration.service';
import { ReportingSettingsComponent } from './reporting-settings/reporting-settings.component';

@NgModule({
    declarations: [
        ReportingSettingsComponent
    ],
    imports: [
        SharedModule,
        ButtonsModule,
        UIRouterModule.forChild({ states: [reportingServicesIntegrationState] })
    ],
    providers: [
        ReportingIntegrationSettingsService
    ],
    exports: [
    ],
    entryComponents: [ReportingSettingsComponent]
})
export class ReportingServicesIntegrationModule { }