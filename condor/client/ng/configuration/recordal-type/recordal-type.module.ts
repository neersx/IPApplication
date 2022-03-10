import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { ButtonsModule } from 'shared/component/buttons/buttons.module';
import { SharedModule } from 'shared/shared.module';
import { MaintainRecordalTypeComponent } from './maintain-recordal-type/maintain-recordal-type.component';
import { RecordalElementComponent } from './maintain-recordal-type/recordal-element/recordal-element.component';
import { recordalType } from './recordal-type-states';
import { RecordalTypeComponent } from './recordal-type.component';
import { RecordalTypeService } from './recordal-type.service';

@NgModule({
    declarations: [
        RecordalTypeComponent,
        MaintainRecordalTypeComponent,
        RecordalElementComponent
    ],
    imports: [
        SharedModule,
        ButtonsModule,
        UIRouterModule.forChild({ states: [recordalType] })
    ],
    providers: [
        RecordalTypeService
    ],
    exports: [
    ],
    entryComponents: [RecordalTypeComponent, MaintainRecordalTypeComponent]
})
export class RecordalTypeModule { }