import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { UIRouterModule } from '@uirouter/angular';
import { AjsUpgradedProviderModule } from 'ajs-upgraded-providers/ajs-upgraded-provider.module';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { CaseViewNameViewModule } from 'common/case-name/case-name.module';
import { CoreModule } from 'core/core.module';
import { SharedModule } from 'shared/shared.module';
import { NameViewTopicBaseComponent } from './name-view-topics.base.component';
import { NameViewComponent } from './name-view.component';
import { NameViewService } from './name-view.service';
import { NameViewState } from './name-view.states';
import { SupplierDetailsComponent } from './supplier-details/supplier-details.component';
import { TrustAccountingDetailsComponent } from './trust-accounting/trust-accounting-details.component';
import { TrustAccountingComponent } from './trust-accounting/trust-accounting.component';

export let routeStates = [NameViewState];

@NgModule({
    declarations: [
        NameViewComponent,
        NameViewTopicBaseComponent,
        SupplierDetailsComponent,
        TrustAccountingComponent,
        TrustAccountingDetailsComponent
    ],
    imports: [
        CommonModule,
        RouterModule,
        UIRouterModule.forChild({ states: routeStates }),
        AjsUpgradedProviderModule,
        FormsModule,
        ReactiveFormsModule,
        SharedModule,
        CoreModule,
        CaseViewNameViewModule
    ],
    providers: [
        NameViewService,
        RootScopeService
    ],
    entryComponents: [SupplierDetailsComponent, TrustAccountingComponent, TrustAccountingDetailsComponent],
    exports: []
})
export class NameViewModule { }
