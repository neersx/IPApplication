
// tslint:disable:only-arrow-functions
import { Ng2StateDeclaration } from '@uirouter/angular';
import { ReportingServicesViewData } from './reporting-services-integration-data';
import { ReportingIntegrationSettingsService } from './reporting-services-integration.service';
import { ReportingSettingsComponent } from './reporting-settings/reporting-settings.component';

export function getReportingConfigSettings(service: ReportingIntegrationSettingsService): Promise<ReportingServicesViewData> {
    return service.getSettings().toPromise();
}

export const reportingServicesIntegrationState: Ng2StateDeclaration = {
    name: 'reportingSettings',
    url: '/configuration/reporting-settings',
    component: ReportingSettingsComponent,
    data: {
        pageTitle: 'reportingServices.configuration.pageTitle'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [ReportingIntegrationSettingsService],
                resolveFn: getReportingConfigSettings
            }
        ]
};