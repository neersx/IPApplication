import { HttpClientModule } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { TreeViewModule } from '@progress/kendo-angular-treeview';
import { UIRouterModule } from '@uirouter/angular';
import { SavedSearchComponent } from 'search/savedsearch/saved-search.component';
import { SavedSearchModule } from 'search/savedsearch/saved-search.module';
import { SavedSearchService } from 'search/savedsearch/saved-search.service';
import { BaseCommonModule } from 'shared/base.common.module';
import { SharedModule } from 'shared/shared.module';
import { searchPresentationState } from './search-presentation-routing.states';
import { SearchPresentationComponent } from './search-presentation.component';
import { SearchPresentationPersistenceService } from './search-presentation.persistence.service';
import { SearchPresentationService } from './search-presentation.service';

export let routeStates = [searchPresentationState];

@NgModule({
    declarations: [
        SearchPresentationComponent,
        SavedSearchComponent
    ],
    imports: [
        BaseCommonModule,
        UIRouterModule.forChild({ states: routeStates }),
        SharedModule,
        HttpClientModule,
        TreeViewModule,
        SavedSearchModule
    ],
    providers: [
        SearchPresentationService,
        SearchPresentationPersistenceService,
        SavedSearchService
    ],
    entryComponents: [SavedSearchComponent]
})
export class SearchPresentationModule {}