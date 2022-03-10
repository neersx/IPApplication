import { CommonModule } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { ContextMenuModule } from '@progress/kendo-angular-menu';
import { TreeViewModule } from '@progress/kendo-angular-treeview';
import { UIRouterModule } from '@uirouter/angular';
import { CasesCoreModule } from 'cases/core/cases.core.module';
import { KnownNameTypes } from 'names/knownnametypes';
import { NamesModule } from 'names/names.module';
import { CaseValidCombinationService } from 'portfolio/case/case-valid-combination.service';
import { CaseListModalService } from 'search/common/case-list-modal.service';
import { SearchHelperService } from 'search/common/search-helper.service';
import { StepsPersistenceService } from 'search/multistepsearch/steps.persistence.service';
import { SharedModule } from 'shared/shared.module';
import { IpxMultiStepSearchComponent } from '../multistepsearch/ipx-multistepsearch.component';
import { CaseSearchState, CaseState, SanityCheckResults } from './case-search-routing.states';
import { AttributesComponent, DataManagementComponent, DesignElementComponent, DetailsComponent, EventActionsComponent, NamesComponent, OtherDetailsComponent, PatentTermAdjustmentsComponent, ReferencesComponent, StatusComponent, TextComponent } from './case-search-topics';
import { CaseSearchTopicBaseComponent } from './case-search-topics/case-search-topics.base.component';
import { CaseSearchComponent } from './case-search.component';
import { CaseSearchService } from './case-search.service';
import { CaseTopicsDataService } from './case-topics-data.service';
import { DueDateFilterService } from './due-date/due-date-filter.service';
import { DueDateComponent } from './due-date/due-date.component';
import { BulkPolicingRequestComponent } from './results/bulk-policing-request/bulk-policing-request.component';
import { BulkPolicingService } from './results/bulk-policing-request/bulk-policing-service';
import { IpxCaseSearchSummaryComponent } from './results/case-search-summary-details/case-search-summary.component';
import { SanityCheckResultsComponent } from './results/sanity-check/sanity-check-results.component';
import { SanityCheckResultsService } from './results/sanity-check/sanity-check-results.service';

export let routeStates = [CaseState, CaseSearchState, SanityCheckResults];
@NgModule({
    declarations: [
        CaseSearchComponent,
        ReferencesComponent,
        AttributesComponent,
        DataManagementComponent,
        DesignElementComponent,
        DetailsComponent,
        EventActionsComponent,
        NamesComponent,
        OtherDetailsComponent,
        PatentTermAdjustmentsComponent,
        StatusComponent,
        TextComponent,
        CaseSearchTopicBaseComponent,
        IpxMultiStepSearchComponent,
        IpxCaseSearchSummaryComponent,
        DueDateComponent,
        SanityCheckResultsComponent,
        BulkPolicingRequestComponent
    ],
    imports: [
        CommonModule,
        UIRouterModule.forChild({ states: routeStates }),
        SharedModule,
        HttpClientModule,
        CasesCoreModule,
        TreeViewModule,
        ContextMenuModule,
        NamesModule
    ],
    providers: [
        CaseSearchService,
        SearchHelperService,
        CaseValidCombinationService,
        CaseTopicsDataService,
        KnownNameTypes,
        StepsPersistenceService,
        DueDateFilterService,
        SanityCheckResultsService,
        BulkPolicingService,
        CaseListModalService
    ],
    exports: [
        IpxCaseSearchSummaryComponent
    ],
    entryComponents: [ReferencesComponent, AttributesComponent, DataManagementComponent, DesignElementComponent,
        DetailsComponent, EventActionsComponent, NamesComponent, OtherDetailsComponent, PatentTermAdjustmentsComponent,
        StatusComponent, TextComponent, DueDateComponent, BulkPolicingRequestComponent]
})
export class CaseSearchModule { }