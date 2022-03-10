import { NgModule } from '@angular/core';
import { SharedModule } from 'shared/shared.module';
import { AdjustValueComponent } from './adjust-value.component';

@NgModule({
    imports: [
        SharedModule
    ],
    declarations: [
        AdjustValueComponent
    ],
    exports: [
        AdjustValueComponent
    ]
})
export class AdjustValueModule { }