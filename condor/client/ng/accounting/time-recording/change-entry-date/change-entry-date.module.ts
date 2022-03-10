// Angular Imports
import { NgModule } from '@angular/core';

// This Module's Components
import { SharedModule } from 'shared/shared.module';
import { ChangeEntryDateComponent } from './change-entry-date.component';

@NgModule({
    imports: [
        SharedModule
    ],
    declarations: [
        ChangeEntryDateComponent
    ],
    exports: [
        ChangeEntryDateComponent
    ]
})
export class ChangeEntryDateModule {}
