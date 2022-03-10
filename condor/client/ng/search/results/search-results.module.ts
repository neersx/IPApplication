import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
// import { GroupItemsComponent } from 'dev/kendo-grid-grouping-demo/group-items.component';
import { NamesModule } from 'names/names.module';
import { CaseSearchModule } from 'search/case/case-search.module';
import { CaseWebLinksTaskProvider } from 'search/common/case-web-links-task-provider';
import { SearchTypeActionMenuProvider } from 'search/common/search-type-action-menus.provider';
import { SearchTypeBillingWorksheetProviderService } from 'search/common/search-type-billing-worksheet-provider.service';
import { SearchTypeBillingWorksheetProvider } from 'search/common/search-type-billing-worksheet.provider';
import { SearchTypeMenuProviderService } from 'search/common/search-type-menu-provider.service';
import { SearchTypeTaskMenusProvider } from 'search/common/search-type-task-menus.provider';
import { SearchTypeTaskPlannerProvider } from 'search/common/search-type-task-planner.provider';
import { IPXKendoGridSelectAllService } from 'shared/component/grid/ipx-kendo-grid-selectall.service';
import { IpxGroupingService } from 'shared/component/grid/ipx-kendo-grouping.service';
import { SharedModule } from 'shared/shared.module';
import { SearchExportService } from '../results/search-export.service';
import { SearchResultPermissionsEvaluator } from './search-result-permissions-evaluator';
import { searchResultsState } from './search-result.states';
import { SearchResultsComponent } from './search-results.component';
import { CaseSerachResultFilterService } from './search-results.filter.service';

@NgModule({
  imports: [
    SharedModule,
    CaseSearchModule,
    NamesModule,
    UIRouterModule.forChild({ states: [searchResultsState] })
  ],
  declarations: [SearchResultsComponent],
  providers: [SearchTypeMenuProviderService, SearchTypeBillingWorksheetProviderService,
    SearchResultPermissionsEvaluator, SearchTypeTaskMenusProvider, SearchTypeActionMenuProvider,
    SearchTypeBillingWorksheetProvider, SearchTypeTaskPlannerProvider, SearchExportService, CaseSerachResultFilterService, IPXKendoGridSelectAllService, IpxGroupingService, CaseWebLinksTaskProvider],
  exports: [SearchResultsComponent]
})
export class ResultsModule { }
