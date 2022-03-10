import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { UIRouterModule } from '@uirouter/angular';
import { FinancialsModule } from 'accounting/financials/financials.module';
import { WarningService } from 'accounting/warnings/warning-service';
import { CasenamesWarningsComponent, NameOnlyWarningsComponent, WarningsModule } from 'accounting/warnings/warnings.module';
import { AjsUpgradedProviderModule } from 'ajs-upgraded-providers/ajs-upgraded-provider.module';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { CoreModule } from 'core/core.module';
import { PortfolioModule } from 'portfolio/portfolio.module';
import { CaseWebLinksTaskProvider } from 'search/common/case-web-links-task-provider';
import { PipesModule } from 'shared/pipes/pipes.module';
import { SharedModule } from 'shared/shared.module';
import { AdjustValueComponent } from './adjust-value/adjust-value.component';
import { AdjustValueModule } from './adjust-value/adjust-value.module';
import { AdjustValueService } from './adjust-value/adjust-value.service';
import { CaseBillNarrativeComponent } from './case-bill-narrative/case-bill-narrative.component';
import { CaseBillNarrativeService } from './case-bill-narrative/case-bill-narrative.service';
import { CaseSummaryDetailsComponent } from './case-summary-details/case-summary-details.component';
import { CaseSummaryService } from './case-summary-details/case-summary.service';
import { ChangeEntryDateComponent } from './change-entry-date/change-entry-date.component';
import { ChangeEntryDateModule } from './change-entry-date/change-entry-date.module';
import { CopyTimeEntryComponent } from './copy-time-entry/copy-time-entry.component';
import { DuplicateEntryComponent } from './duplicate-entry/duplicate-entry.component';
import { DuplicateEntryService } from './duplicate-entry/duplicate-entry.service';
import { ContinuedTimeHelper } from './helpers/continued-time-helper';
import { TimeGridHelper } from './helpers/time-grid-helper';
import { TimeOverlapsHelper } from './helpers/time-overlaps-helper';
import { DebtorSplitsComponent } from './multi-debtor/debtor-splits.component';
import { PostTimeResponseDlgComponent } from './post-time/post-time-response-dlg/post-time-response-dlg.component';
import { PostTimeResponseDlgModule } from './post-time/post-time-response-dlg/post-time-response-dlg.module';
import { PostTimeComponent } from './post-time/post-time.component';
import { PostTimeModule } from './post-time/post-time.module';
import { PostTimeService } from './post-time/post-time.service';
import { TimeRecordingQueryModule } from './query/time-recording-query.module';
import { TimeSettingsService } from './settings/time-settings.service';
import { UserInfoService } from './settings/user-info.service';
import { TimeCalculationService } from './time-calculation.service';
import { TimeGapsComponent } from './time-gaps/time-gaps.component';
import { TimeRecordingHeaderComponent } from './time-recording-header/time-recording-header.component';
import { TimeRecordingForCaseState, TimeRecordingQueryState, TimeRecordingState } from './time-recording-routing.states';
import { TimeRecordingService } from './time-recording-service';
import { TimeRecordingComponent } from './time-recording.component';
import { TimesheetFormsService } from './timesheet-forms.service';

export let routeStates = [TimeRecordingState, TimeRecordingQueryState, TimeRecordingForCaseState];

@NgModule({
    declarations: [
        TimeRecordingComponent,
        CaseSummaryDetailsComponent,
        TimeRecordingHeaderComponent,
        TimeGapsComponent,
        DuplicateEntryComponent,
        CopyTimeEntryComponent,
        DebtorSplitsComponent,
        CaseBillNarrativeComponent
    ],
    imports: [
        CommonModule,
        RouterModule,
        UIRouterModule.forChild({ states: routeStates }),
        AjsUpgradedProviderModule,
        FormsModule,
        ReactiveFormsModule,
        FinancialsModule,
        SharedModule,
        CoreModule,
        PortfolioModule,
        ChangeEntryDateModule,
        PostTimeModule,
        PostTimeResponseDlgModule,
        AdjustValueModule,
        PipesModule,
        TimeRecordingQueryModule,
        WarningsModule
    ],
    providers: [
        TimeRecordingService,
        TimeGridHelper,
        TimeCalculationService,
        CaseSummaryService,
        RootScopeService,
        PostTimeService,
        TimeSettingsService,
        TimesheetFormsService,
        AdjustValueService,
        UserInfoService,
        DuplicateEntryService,
        ContinuedTimeHelper,
        WarningService,
        TimeOverlapsHelper,
        CaseBillNarrativeService,
        CaseWebLinksTaskProvider
    ],
    entryComponents: [
        NameOnlyWarningsComponent,
        CasenamesWarningsComponent,
        ChangeEntryDateComponent,
        PostTimeComponent,
        PostTimeResponseDlgComponent,
        AdjustValueComponent,
        TimeGapsComponent,
        DuplicateEntryComponent,
        CaseBillNarrativeComponent],
    exports: [TimeGapsComponent]
})
export class TimeRecordingModule { }