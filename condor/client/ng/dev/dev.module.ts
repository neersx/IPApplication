import { LOCALE_ID, NgModule } from '@angular/core';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { InputsModule } from '@progress/kendo-angular-inputs';
import { TreeViewModule } from '@progress/kendo-angular-treeview';
import { UIRouterModule } from '@uirouter/angular';
import { AjsUpgradedProviderModule } from 'ajs-upgraded-providers/ajs-upgraded-provider.module';
import { CaseViewModule } from 'cases';
import { CaseViewNameViewModule } from 'common/case-name/case-name.module';
import { MultiFactorAuthenticationModule } from 'rightbarnav/userinfo/mfa/multi-factor-authentication.module';
import { SharedModule } from 'shared/shared.module';
import { LocaleService } from '../core/locale.service';
import { CaseAttachmentComponent } from './case-attachment/case-attachment.component';
import { CheckboxExampleComponent } from './checkbox/checkbox-example.component';
import { ColorPickerExampleComponent } from './color-picker/color-picker-example/color-picker-example.component';
import { DataTypeExampleComponent } from './dataType/datatype-example.component';
import { DatePickerComponent } from './date-picker/date-picker.component.dev';
import { caseAttachmentState, checkBoxState, colorpickerState, datePickerState, dragdrop, dropdownOperatorState, dropdownState, inlineDialogState, ipxdatatypeState, ipxdatepickerState, ipxTextBoxState, ipxTopicsState, ipxTypeaheadState, kendoGridDemoState, kendoGridEditDragDropState, kendoGridGroupingDemoState, kendoGridVirtualScrollingState, kotState, pageTitleTestState, policingState, policingStatusState, radioButtonState, resizerState, richTextFieldState, shortCutState, storageState, timePickerState, validatorsState } from './dev.states';
import { DragDropExampleComponent } from './drag-drop/dragdrop-example.component';
import { KendoGridDragItemExampleDirective } from './drag-drop/kendogrid-drag-item-example.directive';
import { KendoTreeDragItemExampleDirective } from './drag-drop/kendotree-drag-item-example.directive';
import { DropdownOperatorExampleComponent } from './dropdown-operator/dropdown-operator-example.component';
import { DropdownExampleComponent } from './dropdown/dropdown-example.component';
import { InlineDialogExampleComponent } from './inline-dialog/inline-dialog-example.component';
import { IpxDatepickerExampleComponent } from './ipx-datepicker/ipx-datepicker-example.component';
import { IpxTextBoxExampleComponent } from './ipx-form-controls/textbox-examples.component';
import { KotPanelExampleComponent } from './ipx-kot-panel/kot-panel-example.component';
import { RichtextExampleComponent } from './ipx-richtext-field/richtext-example/richtext-example.component';
import { CharacteristicsComponent } from './ipx-topics/characteristics.component';
import { EventsComponent } from './ipx-topics/events.component';
import { EventsDueComponent } from './ipx-topics/events.due.component';
import { EventsOccuredComponent } from './ipx-topics/events.occured.component';
import { ReferencesComponent } from './ipx-topics/references.component';
import { TopicsExampleComponent } from './ipx-topics/topics-example.component';
import { IpxDevTypeaheadComponent } from './ipx-typeahead/ipx-typeahead.dev.component';
import { KendoGridDemoComponent } from './kendo-grid-demo/kendo-grid-demo.component';
import { KendoGridEditDragDropDemoComponent } from './kendo-grid-edit-dragdrop-demo/kendo-grid-edit-dragdrop-demo.component';
import { KendoGridGroupingDemoComponent } from './kendo-grid-grouping-demo/kendo-grid-grouping-demo.component';
import { PolicingTestComponent } from './kendo-grid/policing-example.component';
import { KendoGridVirtualScrollingComponent } from './kendo-virtual-scrolling/kendo-grid-virtual-scrolling.component';
import { PageTitleTestComponent } from './page/page.component.dev';
import { PolicingStatusComponent } from './policing-status/policing-status.component';
import { RadiobuttonExampleComponent } from './radiobutton/radiobutton-example.component';
import { ResizerExampleComponent } from './resizer/resizer-example.component';
import { KeyboardShortCutExampleComponent } from './shortcuts/keyboardshortcut.component';
import { StorageComponent } from './storage/storage-example.component';
import { TimePickerDevComponent } from './time-picker/time-picker.component.dev';
import { ValidatorExamplesComponent } from './validators/validator-examples/validator-examples.component';

export let routeStates = [policingState, datePickerState, dragdrop, pageTitleTestState, ipxTypeaheadState, storageState, kendoGridDemoState, kendoGridGroupingDemoState, kendoGridEditDragDropState, kendoGridVirtualScrollingState, inlineDialogState, resizerState, ipxTopicsState, ipxTextBoxState, dropdownState, dropdownOperatorState, checkBoxState, radioButtonState, timePickerState, policingStatusState, shortCutState, ipxdatepickerState, ipxdatatypeState, validatorsState, richTextFieldState, colorpickerState, kotState, caseAttachmentState];
@NgModule({
   declarations: [
      PolicingTestComponent,
      DatePickerComponent,
      IpxDevTypeaheadComponent,
      PageTitleTestComponent,
      StorageComponent,
      KendoGridDemoComponent,
      KendoGridGroupingDemoComponent,
      InlineDialogExampleComponent,
      CharacteristicsComponent,
      EventsComponent,
      EventsDueComponent,
      EventsOccuredComponent,
      ReferencesComponent,
      TopicsExampleComponent,
      ResizerExampleComponent,
      IpxTextBoxExampleComponent,
      DropdownExampleComponent,
      DropdownOperatorExampleComponent,
      TimePickerDevComponent,
      CheckboxExampleComponent,
      RadiobuttonExampleComponent,
      PolicingStatusComponent,
      KeyboardShortCutExampleComponent,
      IpxDatepickerExampleComponent,
      DataTypeExampleComponent,
      ValidatorExamplesComponent,
      DragDropExampleComponent,
      KendoGridDragItemExampleDirective,
      KendoTreeDragItemExampleDirective,
      RichtextExampleComponent,
      ColorPickerExampleComponent,
      KotPanelExampleComponent,
      CaseAttachmentComponent,
      KendoGridVirtualScrollingComponent,
      KendoGridEditDragDropDemoComponent
   ],
   imports: [
      BrowserAnimationsModule,
      AjsUpgradedProviderModule,
      UIRouterModule.forChild({ states: routeStates }),
      MultiFactorAuthenticationModule,
      SharedModule,
      TreeViewModule,
      CaseViewModule,
      InputsModule,
      CaseViewNameViewModule
   ],
   providers: [LocaleService, { provide: LOCALE_ID, useValue: 'en' }]
})
export class DevModule { }
