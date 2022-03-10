import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { ButtonsModule } from 'shared/component/buttons/buttons.module';
import { SharedModule } from 'shared/shared.module';
import { KotMaintainConfigComponent } from './kot-maintain-config/kot-maintain-config.component';
import { kotTextTypesCase, kotTextTypesName } from './kot-text-types-states';
import { KotTextTypesComponent } from './kot-text-types.component';
import { KotTextTypesService } from './kot-text-types.service';

@NgModule({
    declarations: [
        KotTextTypesComponent,
        KotMaintainConfigComponent
    ],
    imports: [
        SharedModule,
        ButtonsModule,
        UIRouterModule.forChild({ states: [kotTextTypesCase, kotTextTypesName] })
    ],
    providers: [
        KotTextTypesService
    ],
    exports: [
    ],
    entryComponents: [KotTextTypesComponent, KotMaintainConfigComponent]
})
export class KeepOnTopNotesModule { }