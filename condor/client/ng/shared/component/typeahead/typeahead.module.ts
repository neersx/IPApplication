import { CUSTOM_ELEMENTS_SCHEMA, NgModule } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { TranslateModule } from '@ngx-translate/core';
import { NamesModule } from 'names/names.module';
import { BaseCommonModule } from 'shared/base.common.module';
import { ElementComputedStyleDirective } from 'shared/directives/computed-style.directive';
import { ButtonsModule } from '../buttons/buttons.module';
import { FormControlsModule } from '../forms/form-controls.module';
import { IpxKendoGridModule } from '../grid/ipx-kendo-grid.module';
import { IpxInlineAlertModule } from '../notification/ipx-inline-alert/ipx-inline-alert.module';
import { TooltipModule } from '../tooltip/tooltip.module';
import { UtilityModule } from '../utility/utility.module';
import { PageModule } from './../page/page.module';
import { AutoCompleteHighlightedDirective, DynamicItemTemplateComponent, IpxAutocompleteComponent, ItemCodeComponent, ItemCodeDescComponent, ItemCodeValueComponent, ItemDescComponent, ItemIdDescComponent, ItemNameDescComponent, TemplateHostDirective } from './ipx-autocomplete';
import { ItemCodeDescKeyComponent } from './ipx-autocomplete/autocomplete/item-code-desc-key.component';
import { IpxDefaultJurisdictionComponent } from './ipx-picklist/ipx-default-jurisdiction/ipx-default-jurisdiction.component';
import { IpxPicklistCaseSearchPanelComponent } from './ipx-picklist/ipx-picklist-case-search-panel/ipx-picklist-case-search-panel.component';
import { IpxPicklistMaintenanceService } from './ipx-picklist/ipx-picklist-maintenance.service';
import { CaseListPicklistComponent } from './ipx-picklist/ipx-picklist-modal-maintenance/case-list-picklist/case-list-picklist.component';
import { IpxCaselistPicklistService } from './ipx-picklist/ipx-picklist-modal-maintenance/case-list-picklist/ipx-caselist-picklist.service';
import { IpxPicklistColumnGroupComponent } from './ipx-picklist/ipx-picklist-modal-maintenance/column-group/column-group.component';
import { DataItemPicklistComponent } from './ipx-picklist/ipx-picklist-modal-maintenance/data-item-picklist/data-item-picklist.component';
import { IpxDataItemService } from './ipx-picklist/ipx-picklist-modal-maintenance/data-item-picklist/ipx-dataitem-picklist.service';
import { FilePartPicklistComponent } from './ipx-picklist/ipx-picklist-modal-maintenance/file-part-picklist/file-part-picklist.component';
import { IpxPicklistInstructionTypeComponent } from './ipx-picklist/ipx-picklist-modal-maintenance/ipx-picklist-maintenance-templates/instruction-type/instruction-type.component';
import { IpxPicklistModelHostDirective } from './ipx-picklist/ipx-picklist-modal-maintenance/ipx-picklist-maintenance-templates/ipx-picklist-model-host.directive';
import { QuestionPicklistComponent } from './ipx-picklist/ipx-picklist-modal-maintenance/question-picklist/question-picklist.component';
import { IpxQuestionPicklistService } from './ipx-picklist/ipx-picklist-modal-maintenance/question-picklist/question-picklist.service';
import { IpxPicklistSaveSearchMenuComponent } from './ipx-picklist/ipx-picklist-modal-maintenance/save-search-menu/search-menu.component';
import { TaskPlannerPicklistComponent } from './ipx-picklist/ipx-picklist-modal-maintenance/task-panner-picklist/task-planner-picklist.component';
import { IpxPicklistModalSearchResultsComponent } from './ipx-picklist/ipx-picklist-modal-search-results/ipx-picklist-modal-search-results.component';
import { IpxPicklistModalService } from './ipx-picklist/ipx-picklist-modal.service';
import { IpxPicklistModalComponent } from './ipx-picklist/ipx-picklist-modal/ipx-picklist-modal.component';
import { IpxPicklistSearchFieldComponent } from './ipx-picklist/ipx-picklist-search-field/ipx-picklist-search-field.component';
import { IpxTypeaheadComponent, TypeaheadHighlight } from './ipx-typeahead';

const typeaheadComponents = [
  IpxAutocompleteComponent,
  DynamicItemTemplateComponent,
  IpxTypeaheadComponent,
  IpxPicklistInstructionTypeComponent,
  IpxPicklistSaveSearchMenuComponent,
  IpxPicklistColumnGroupComponent,
  DataItemPicklistComponent,
  CaseListPicklistComponent,
  FilePartPicklistComponent,
  TaskPlannerPicklistComponent,
  QuestionPicklistComponent
];

const pickListComponents = [
  IpxPicklistModalComponent,
  IpxPicklistModalSearchResultsComponent,
  IpxPicklistSearchFieldComponent,
  IpxDefaultJurisdictionComponent,
  IpxPicklistCaseSearchPanelComponent
];

const typeaheadEntryComponents = [
  ItemCodeDescComponent,
  ItemCodeComponent,
  ItemDescComponent,
  ItemCodeValueComponent,
  ItemNameDescComponent,
  ItemIdDescComponent,
  ItemCodeDescKeyComponent
];

const typeaheadDirectives = [
  AutoCompleteHighlightedDirective,
  TypeaheadHighlight,
  TemplateHostDirective
];

const directives = [
  ElementComputedStyleDirective,
  IpxPicklistModelHostDirective
];
@NgModule({
  imports: [BaseCommonModule, FormsModule, ReactiveFormsModule, TranslateModule, TooltipModule, ButtonsModule, IpxKendoGridModule, FormControlsModule, UtilityModule, NamesModule, IpxInlineAlertModule, PageModule],
  declarations: [
    ...directives,
    ...typeaheadComponents,
    ...typeaheadEntryComponents,
    ...typeaheadDirectives,
    ...pickListComponents
  ],
  exports: [
    ...directives,
    ...typeaheadComponents,
    ...typeaheadEntryComponents,
    ...typeaheadDirectives,
    ...pickListComponents],
  providers: [
    IpxPicklistModalService,
    IpxPicklistMaintenanceService,
    IpxDataItemService,
    IpxCaselistPicklistService,
    IpxQuestionPicklistService
  ],
  entryComponents: [...typeaheadComponents, ...typeaheadEntryComponents, ...pickListComponents],
  schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class IpxTypeaheadModule { }
