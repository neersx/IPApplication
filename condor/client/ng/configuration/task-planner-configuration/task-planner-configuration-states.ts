// tslint:disable: only-arrow-functions
import { Ng2StateDeclaration } from '@uirouter/angular';
import { TaskPlannerConfigurationComponent } from './task-planner-configuration.component';

export const taskPlannerConfig: Ng2StateDeclaration = {
    name: 'taskPlannerConfig',
    url: '/configuration/task-planner-configuration',
    component: TaskPlannerConfigurationComponent,
    data: {
        pageTitle: 'taskPlannerConfig.title'
    }
};