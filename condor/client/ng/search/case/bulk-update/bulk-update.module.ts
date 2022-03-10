import { CommonModule } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { CasesCoreModule } from 'cases/core/cases.core.module';
import { SharedModule } from 'shared/shared.module';
import { CaseBulkUpdate } from '../case-search-routing.states';
import { BulkUpdateConfirmationComponent } from './bulk-update-confirmation/bulk-update-confirmation.component';
import { StatusUpdateConfirmationComponent } from './bulk-update-confirmation/status-update-confirmation.component';
import { BulkUpdateComponent } from './bulk-update.component';
import { BulkUpdateService } from './bulk-update.service';
import { CaseNameReferenceUpdateComponent } from './case-name-reference-update/case-name-reference-update.component';
import { CaseTextUpdateComponent } from './case-text-update/case-text-update.component';
import { FieldUpdateComponent } from './field-update/field-update.component';
import { FileLocationUpdateComponent } from './file-location-update/file-location-update.component';
import { CaseStatusUpdateComponent } from './status-update/status-update.component';

export let routeStates = [CaseBulkUpdate];

@NgModule({
    declarations: [
        BulkUpdateComponent,
        FieldUpdateComponent,
        BulkUpdateConfirmationComponent,
        CaseTextUpdateComponent,
        CaseNameReferenceUpdateComponent,
        FileLocationUpdateComponent,
        CaseStatusUpdateComponent,
        StatusUpdateConfirmationComponent
    ],
    imports: [
        CommonModule,
        UIRouterModule.forChild({ states: routeStates }),
        SharedModule,
        HttpClientModule,
        CasesCoreModule
    ],
    providers: [
        BulkUpdateService
    ],
    entryComponents: [
        FieldUpdateComponent,
        BulkUpdateConfirmationComponent,
        CaseTextUpdateComponent,
        CaseNameReferenceUpdateComponent,
        FileLocationUpdateComponent,
        CaseStatusUpdateComponent,
        StatusUpdateConfirmationComponent
    ]
})
export class BulkUpdateModule { }