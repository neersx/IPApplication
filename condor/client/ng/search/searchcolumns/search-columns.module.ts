import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { SharedModule } from 'shared/shared.module';
import { SearchColumnMaintenanceComponent } from './search-column.maintenance.component';
import { SearchColumnsComponent } from './search-columns-component';
import { searchColumnsState } from './search-columns-routing.states';
import { SearchColumnsService } from './search-columns.service';

export let routeStates = [searchColumnsState];

@NgModule({
  imports: [
    SharedModule,
    UIRouterModule.forChild({ states: [searchColumnsState] })
  ],
  declarations: [SearchColumnsComponent, SearchColumnMaintenanceComponent],
  providers: [SearchColumnsService],
  exports: [SearchColumnsComponent],
  entryComponents: [SearchColumnMaintenanceComponent]
})
export class ColumnsModule { }
