import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { AlertModule } from 'ngx-bootstrap/alert';
import { checklistConfigurationState } from './checklists/checklists-states';
import { ChecklistConfigurationModule } from './checklists/checklists.module';
import { ScreenDesignerModule } from './screen-designer/screen-designer.module';

@NgModule({
    imports: [
        AlertModule,
        ScreenDesignerModule,
        ChecklistConfigurationModule,
        UIRouterModule.forChild({
            states: [
                checklistConfigurationState
            ]
        })
    ],
    declarations: [
    ],
    exports: [
        ScreenDesignerModule,
        ChecklistConfigurationModule
    ]
})
export class RulesModule { }
