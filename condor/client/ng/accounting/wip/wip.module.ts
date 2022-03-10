import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { SharedModule } from './../../shared/shared.module';
import { AdjustWipComponent } from './adjust-wip/adjust-wip.component';

@NgModule({
    declarations: [
        AdjustWipComponent
    ],
    imports: [CommonModule, SharedModule],
    exports: [AdjustWipComponent],
    providers: []
})
export class WipModule { }
