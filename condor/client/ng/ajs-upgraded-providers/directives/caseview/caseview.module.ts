import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { CaseClassesComponent, CaseClassesDirective } from './case-classes.component';
import { CaseDesignatedCountriesComponent, CaseDesignatedCountriesDirective } from './case-designated-countries.component';
import { CaseEFilingComponent, CaseEFilingDirective } from './case-e-filing.component';
import { CaseEventsComponent, CaseEventsDirective } from './case-events.component';
import { CaseImagesComponent, CaseImagesDirective } from './case-images.component';
import { CaseNamesComponent, CaseNamesDirective } from './case-names.component';
import { CaseSummaryComponent, CaseSummaryDirective } from './case-summary.component';
import { CaseTextsComponent, CaseTextsDirective } from './case-texts.component';

const components = [
  CaseSummaryComponent,
  CaseNamesComponent,
  CaseClassesComponent,
  CaseDesignatedCountriesComponent,
  CaseEFilingComponent,
  CaseTextsComponent,
  CaseImagesComponent,
  CaseEventsComponent
];
const directives = [
  CaseNamesDirective,
  CaseSummaryDirective,
  CaseClassesDirective,
  CaseDesignatedCountriesDirective,
  CaseEFilingDirective,
  CaseTextsDirective,
  CaseImagesDirective,
  CaseEventsDirective
];

@NgModule({
  exports: [
    ...directives,
    ...components
  ],
  declarations: [
    ...directives,
    ...components
  ],
  entryComponents: [
    ...components
  ],
  imports: [
    CommonModule
  ]
})
export class CaseviewUpgradedComponentsModule { }
