import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { ButtonsModule } from 'shared/component/buttons/buttons.module';
import { SharedModule } from 'shared/shared.module';
import { taskPlannerConfig } from './task-planner-configuration-states';
import { TaskPlannerConfigurationComponent } from './task-planner-configuration.component';
import { TaskPlannerConfigurationService } from './task-planner-configuration.service';

@NgModule({
    declarations: [
        TaskPlannerConfigurationComponent
    ],
    imports: [
        SharedModule,
        ButtonsModule,
        UIRouterModule.forChild({ states: [taskPlannerConfig] })
    ],
    providers: [
        TaskPlannerConfigurationService
    ],
    exports: [
    ],
    entryComponents: [TaskPlannerConfigurationComponent]
})
export class TaskPlannerConfigurationModule { }