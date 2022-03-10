import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { ButtonsModule } from 'shared/component/buttons/buttons.module';
import { SharedModule } from 'shared/shared.module';
import { DmsDataDownloadComponent } from './data-download/dms-data-download.component';
import { dmsIntegrationState } from './dms-integration-states';
import { DmsIntegrationComponent } from './dms-integration.component';
import { DmsIntegrationService } from './dms-integration.service';
import { IManageDatabaseComponent } from './i-manage/i-manage-database/i-manage-database.component';
import { IManageCredentialsInputComponent } from './i-manage/i-manage-database/i-manage-database/i-manage-credentials-input/i-manage-credentials-input.component';
import { IManageDatabaseModelComponent } from './i-manage/i-manage-database/i-manage-database/i-manage-database-model.component';
import { IManageDataItemsComponent } from './i-manage/i-manage-dataitems/i-manage-dataitems.component';
import { IManageTestWorkspaceComponent } from './i-manage/i-manage-test-workspace/i-manage-test-workspace.component';
import { IManageWorkspacesComponent } from './i-manage/i-manage-workspaces/i-manage-workspaces.component';

const topics = [
    DmsDataDownloadComponent,
    IManageDatabaseComponent
];
const components = [
    IManageDatabaseComponent,
    IManageDatabaseModelComponent,
    IManageDataItemsComponent,
    IManageWorkspacesComponent,
    IManageCredentialsInputComponent,
    IManageTestWorkspaceComponent
];
@NgModule({
    declarations: [
        DmsIntegrationComponent,
        ...components,
        ...topics
    ],
    imports: [
        SharedModule,
        ButtonsModule,
        UIRouterModule.forChild({ states: [dmsIntegrationState] })
    ],
    providers: [
        DmsIntegrationService
    ],
    exports: [
    ],
    entryComponents: [...topics, IManageDatabaseModelComponent, IManageWorkspacesComponent, IManageDataItemsComponent, IManageCredentialsInputComponent, IManageTestWorkspaceComponent]
})
export class DmsIntegrationhModule { }