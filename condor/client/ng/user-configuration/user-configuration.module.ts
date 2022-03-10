import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { SharedModule } from 'shared/shared.module';
import { RoleSearchComponent } from './roles/role-search.component';
import { RoleSearchService } from './roles/role-search.service';
import { RoleSearchMaintenanceComponent } from './roles/roles-details-maintenance/role-search-maintenance.component';
import { RoleDetailsComponent } from './roles/roles-details/role-details.component';
import { RolesOverviewComponent } from './roles/roles-details/roles-overview.component';
import { RolesSubjectComponent } from './roles/roles-details/roles-subject.component';
import { RolesTasksComponent } from './roles/roles-details/roles-tasks.component';
import { RolesWebPartComponent } from './roles/roles-details/roles-webpart.component';
import { roleDetailState, userConfigurationState } from './user-configuration-routing.states';
export let routeStates = [userConfigurationState, roleDetailState];

@NgModule({
  imports: [
    SharedModule,
    UIRouterModule.forChild({ states: routeStates })
  ],
  declarations: [RoleSearchComponent, RoleDetailsComponent, RolesOverviewComponent, RolesTasksComponent, RolesWebPartComponent, RolesSubjectComponent, RoleSearchMaintenanceComponent],
  providers: [RoleSearchService],
  exports: [RoleSearchComponent],
  entryComponents: [RoleSearchMaintenanceComponent]
})
export class UserConfigurationModule { }
