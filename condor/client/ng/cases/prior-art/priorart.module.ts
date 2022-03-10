import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { UIRouterModule } from '@uirouter/angular';
import { AjsUpgradedProviderModule } from 'ajs-upgraded-providers/ajs-upgraded-provider.module';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { CoreModule } from 'core/core.module';
import { SharedModule } from 'shared/shared.module';
import { PriorArtShortcuts } from './helpers/prior-art-shortcuts';
import { PriorartInprotechCasesResultComponent } from './inprotech-cases-result/priorart-inprotech-cases-result.component';
import { LiteratureSearchResultComponent } from './literature-search-result/literature-search-result.component';
import { PriorartNotFoundResultComponent } from './not-found-result/priorart-not-found-result.component';
import { PriorArtDetailsComponent } from './priorart-details/priorart-details.component';
import { CitationsListComponent } from './priorart-maintenance/associated-art/citations-list.component';
import { PriorartCreateSourceComponent } from './priorart-maintenance/create-source/priorart-create-source.component';
import { FamilyCaselistNameComponent } from './priorart-maintenance/family-caselist-name/family-caselist-name.component';
import { FamilyNameCaseDetailsComponent } from './priorart-maintenance/family-caselist-name/family-name-case-details/family-name-case-details.component';
import { AddLinkedCasesComponent } from './priorart-maintenance/linked-cases/add-linked-cases/add-linked-cases.component';
import { LinkedCasesComponent } from './priorart-maintenance/linked-cases/linked-cases.component';
import { UpdateFirstLinkedComponent } from './priorart-maintenance/linked-cases/update-first-linked-case/update-first-linked.component';
import { UpdatePriorArtStatusComponent } from './priorart-maintenance/linked-cases/update-priorart-status/update-priorart-status.component';
import { PriorArtMaintenanceComponent } from './priorart-maintenance/priorart-maintenance.component';
import { PriorArtMultistepComponent } from './priorart-multistep/priorart-multistep.component';
import { PriorArtSearchComponent } from './priorart-search/priorart-search.component';
import { PriorArtComponent } from './priorart.component';
import { PriorArtService } from './priorart.service';
import { PriorArtMaintenanceState, PriorArtState, ReferenceManagementState } from './priorart.states';
import { PriorartSearchResultComponent } from './search-result/priorart-search-result.component';
import { PriorartSourceSearchResultComponent } from './source-search-result/priorart-source-search-result.component';

export let routeStates = [PriorArtState, PriorArtMaintenanceState, ReferenceManagementState];

@NgModule({
    declarations: [
        PriorArtComponent,
        PriorArtSearchComponent,
        PriorartSearchResultComponent,
        PriorartSourceSearchResultComponent,
        LiteratureSearchResultComponent,
        PriorartInprotechCasesResultComponent,
        PriorartNotFoundResultComponent,
        PriorArtDetailsComponent,
        PriorArtMultistepComponent,
        PriorArtMaintenanceComponent,
        PriorartCreateSourceComponent,
        CitationsListComponent,
        LinkedCasesComponent,
        AddLinkedCasesComponent,
        UpdateFirstLinkedComponent,
        UpdatePriorArtStatusComponent,
        FamilyCaselistNameComponent,
        FamilyNameCaseDetailsComponent
    ],
    imports: [
        CommonModule,
        RouterModule,
        UIRouterModule.forChild({ states: routeStates }),
        AjsUpgradedProviderModule,
        FormsModule,
        ReactiveFormsModule,
        SharedModule,
        CoreModule
    ],
    providers: [
        PriorArtService,
        RootScopeService,
        PriorArtShortcuts
    ],
    entryComponents: [
        PriorArtSearchComponent,
        PriorartSearchResultComponent,
        PriorartSourceSearchResultComponent,
        LiteratureSearchResultComponent,
        PriorartInprotechCasesResultComponent,
        PriorartNotFoundResultComponent,
        PriorArtMultistepComponent,
        PriorArtMaintenanceComponent,
        CitationsListComponent,
        LinkedCasesComponent,
        AddLinkedCasesComponent,
        FamilyCaselistNameComponent
    ],
    exports: []
})
export class PriorArtModule { }
