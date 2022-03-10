import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { CasesCoreModule } from 'cases/core/cases.core.module';
import { SharedModule } from 'shared/shared.module';
import { portal2State } from './portal2.states';
import { RecentCasesComponent } from './recent-cases/recent-cases.component';

const states = [ portal2State ];

@NgModule({
  declarations: [RecentCasesComponent],
  imports: [
    SharedModule,
    CommonModule,
    UIRouterModule.forChild({ states}),
    CasesCoreModule
  ]
})
export class Portal2Module { }
