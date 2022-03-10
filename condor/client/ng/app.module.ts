import { HttpClientModule } from '@angular/common/http';
import { NgModule, ElementRef, NgModuleFactoryLoader, SystemJsNgModuleLoader } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { BrowserModule } from '@angular/platform-browser';
import { UpgradeModule } from '@angular/upgrade/static';
import { TranslateLoader, TranslateModule } from '@ngx-translate/core';
import { UIRouterUpgradeModule } from '@uirouter/angular-hybrid';
import { TooltipModule } from 'ngx-bootstrap/tooltip';
import { AjsUpgradedProviderModule } from './ajs-upgraded-providers/ajs-upgraded-provider.module';
import { TranslationService } from 'ajs-upgraded-providers/translation.service.provider';
import { CustomTranslationLoader } from './core/custom-translation-loader';
import { DevModule, DevE2eModule } from 'dev/@modules';
import { environment } from './environments/environment';
import { CommonModule, DatePipe } from '@angular/common';
import { TypeAheadConfigProvider } from './shared/component/typeahead/ipx-typeahead/typeahead.config.provider';
import { TimeRecordingModule } from './accounting/time-recording/time-recording.module';
import { LoggerModule, NgxLoggerLevel } from 'ngx-logger';
import { POPUP_CONTAINER } from '@progress/kendo-angular-popup';
import { EventsComponent } from './dev/ipx-topics/events.component';
import { CharacteristicsComponent } from './dev/ipx-topics/characteristics.component';
import { ReferencesComponent } from './dev/ipx-topics/references.component';
import { EventsDueComponent } from './dev/ipx-topics/events.due.component';
import { EventsOccuredComponent } from './dev/ipx-topics/events.occured.component';
import { CoreModule } from 'core/core.module';
import { PopoverModule } from 'ngx-bootstrap/popover';
import { TooltipConfig } from 'ngx-bootstrap/tooltip';
import { HotkeyModule, HotkeysService } from 'angular2-hotkeys';
import { CaseViewModule } from 'cases';
import { ConfigurationModule } from 'configuration/configuration.module';
import { CaseSearchModule } from './search/case/case-search.module';
import { appCaseRoute } from 'app.routingstates';
import { Portal2Module } from 'portal2/portal2.module';
import { SharedModule } from 'shared/shared.module';
import { TopHeaderModule } from 'shared/component/topheader/topheader.module';
import { TopHeaderComponent } from 'shared/component/topheader/ipx-top-header.component';
import { RightBarNavComponent } from 'rightbarnav/rightbarnav.component';
import { RightBarModule } from 'rightbarnav/rightbarnav.module';
import { SearchPresentationModule } from 'search/presentation/search-presentation.module';
import { HostedModule } from 'hosted/hosted.module';
import { NameViewModule } from './names/name-view/name-view.module'
import { BulkUpdateModule } from 'search/case/bulk-update/bulk-update.module';
import { ResultsModule } from 'search/results/search-results.module';
import { ColumnsModule } from 'search/searchcolumns/search-columns.module';
import { ExternalDependenciesModule } from 'external.dependencies.module';
import { PriorArtModule } from 'cases/prior-art/priorart.module';
import { TaskPlannerModule } from 'search/task-planner/task-planner.module';
import { UploadModule } from '@progress/kendo-angular-upload';
import { BillingModule } from 'accounting/billing/billing.module';
import { DisbursementDissectionModule } from 'accounting/wip/disbusement-dissection/disbursement-dissection.module';
import { UserConfigurationModule } from 'user-configuration/user-configuration.module';
import { WipOverviewModule } from 'search/wip-overview/wip-overview.module';
import { BillSearchModule } from 'search/bill-search/bill-search.module';


export const devModules = environment.includeE2e
    ? [DevModule, DevE2eModule]
    : [];

@NgModule({
    imports: [
        CommonModule,
        BrowserModule,
        FormsModule,
        HttpClientModule,
        TopHeaderModule,
        RightBarModule,
        UpgradeModule,
        HotkeyModule.forRoot({
            disableCheatSheet: true
        }),
        LoggerModule.forRoot({
            serverLoggingUrl: '',
            level: !environment.production ? NgxLoggerLevel.DEBUG : NgxLoggerLevel.OFF,
            serverLogLevel: NgxLoggerLevel.ERROR
        }),
        CoreModule.forRoot(),
        SharedModule.forRoot(),
        UIRouterUpgradeModule.forRoot({ states: [appCaseRoute] }),
        AjsUpgradedProviderModule.forRoot(),
        TranslateModule.forRoot({
            loader: {
                provide: TranslateLoader,
                useClass: CustomTranslationLoader,
                deps: [TranslationService]
            }
        }),
        TooltipModule.forRoot(),
        PopoverModule.forRoot(),
        TimeRecordingModule,
        CaseViewModule,
        Portal2Module,
        CaseSearchModule,
        TaskPlannerModule,
        WipOverviewModule,
        BillSearchModule,
        ConfigurationModule,
        HostedModule,
        SearchPresentationModule,
        ResultsModule,
        ColumnsModule,
        NameViewModule,
        BulkUpdateModule,
        ExternalDependenciesModule,
        PriorArtModule,
        UploadModule,
        DisbursementDissectionModule,
        BillingModule,
        UserConfigurationModule,
        ...devModules
    ],
    providers: [
        TypeAheadConfigProvider,
        HotkeysService,
        DatePipe,
        {
            provide: POPUP_CONTAINER,
            useFactory: () => {
                // This is for the hybrid application as the root element is owned by AngularJs
                // return the container ElementRef, where the popup will be injected
                return { nativeElement: document.body } as ElementRef;
            }
        },
        { provide: NgModuleFactoryLoader, useClass: SystemJsNgModuleLoader },
        TooltipConfig
    ],
    bootstrap: [TopHeaderComponent],
    entryComponents: [CharacteristicsComponent, EventsComponent, ReferencesComponent, EventsDueComponent, EventsOccuredComponent, RightBarNavComponent]
})
export class AppModule {
    // tslint:disable-next-line: no-empty
    ngDoBootstrap(): any { }

    constructor(tooltipConfig: TooltipConfig) {
        tooltipConfig.container = 'body';
        tooltipConfig.triggers = 'hover';
    }
}
