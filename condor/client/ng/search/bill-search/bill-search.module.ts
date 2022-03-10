import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { CasesCoreModule } from 'cases/core/cases.core.module';
import { DatesModule } from 'dates/dates.module';
import { SharedModule } from 'shared/shared.module';
import { BillSearchProvider } from './bill-search.provider';
import { BillSearchService } from './bill-search.service';

@NgModule({
  imports: [
    CommonModule,
    UIRouterModule.forChild({ states: [] }),
    SharedModule,
    CasesCoreModule,
    DatesModule
  ],
  declarations: [],
  providers: [BillSearchService, BillSearchProvider],
  entryComponents: []
})
export class BillSearchModule { }