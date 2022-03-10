import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { TreeViewModule } from '@progress/kendo-angular-treeview';
import { UIRouterModule } from '@uirouter/angular';
import { ButtonsModule } from 'ngx-bootstrap/buttons';
import { TooltipModule } from 'ngx-bootstrap/tooltip';
import { BaseCommonModule } from 'shared/base.common.module';
import { PipesModule } from 'shared/pipes/pipes.module';
import { GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import { SharedModule } from 'shared/shared.module';
import { IpxInheritanceIconComponent } from '../shared/ipx-inheritance-icon/ipx-inheritance-icon.component';
import { InheritanceComponent } from './case/inheritance/inheritance.component';
import { IpxInheritanceDetailComponent } from './case/inheritance/ipx-inheritence-detail/ipx-inheritance-detail.component';
import { CharacteristicsSummaryComponent } from './case/maintenance/characteristics-summary/characteristics-summary.component';
import { MaintenanceComponent } from './case/maintenance/maintenance.component';
import { ScreenDesignerSectionsComponent } from './case/maintenance/sections/screen-designer-sections.component';
import { SearchByCaseComponent } from './case/search/search-by-case/search-by-case.component';
import { SearchByCharacteristicComponent } from './case/search/search-by-characteristic/search-by-characteristic.component';
import { SearchByCriteriaComponent } from './case/search/search-by-criteria/search-by-criteria.component';
import { ScreenDesignerSearchComponent } from './case/search/search.component';
import { SearchService } from './case/search/search.service';
import { inheritanceState, maintenanceState, screenDesignerState } from './screen-designer-states';

@NgModule({
   imports: [
      BaseCommonModule,
      TooltipModule,
      PipesModule,
      ButtonsModule,
      SharedModule,
      TreeViewModule,
      CommonModule,
      UIRouterModule.forChild({
         states: [
            screenDesignerState,
            maintenanceState,
            inheritanceState
         ]
      })
   ],
   declarations: [
      SearchByCriteriaComponent,
      SearchByCaseComponent,
      SearchByCharacteristicComponent,
      ScreenDesignerSearchComponent,
      MaintenanceComponent,
      CharacteristicsSummaryComponent,
      IpxInheritanceIconComponent,
      ScreenDesignerSectionsComponent,
      IpxInheritanceDetailComponent,
      InheritanceComponent
   ],
   entryComponents: [
      CharacteristicsSummaryComponent,
      ScreenDesignerSectionsComponent
   ],
   providers: [
      SearchService,
      GridNavigationService
   ]
})
export class ScreenDesignerModule { }
