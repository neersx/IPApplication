import { Ng2StateDeclaration, Transition } from '@uirouter/angular';
import { PolicingStatusComponent } from '../dev/policing-status/policing-status.component';
import { CaseAttachmentComponent } from './case-attachment/case-attachment.component';
import { CheckboxExampleComponent } from './checkbox/checkbox-example.component';
import { ColorPickerExampleComponent } from './color-picker/color-picker-example/color-picker-example.component';
import { DataTypeExampleComponent } from './dataType/datatype-example.component';
import { DatePickerComponent } from './date-picker/date-picker.component.dev';
import { DragDropExampleComponent } from './drag-drop/dragdrop-example.component';
import { DropdownOperatorExampleComponent } from './dropdown-operator/dropdown-operator-example.component';
import { DropdownExampleComponent } from './dropdown/dropdown-example.component';
import { InlineDialogExampleComponent } from './inline-dialog/inline-dialog-example.component';
import { IpxDatepickerExampleComponent } from './ipx-datepicker/ipx-datepicker-example.component';
import { IpxTextBoxExampleComponent } from './ipx-form-controls/textbox-examples.component';
import { KotPanelExampleComponent } from './ipx-kot-panel/kot-panel-example.component';
import { RichtextExampleComponent } from './ipx-richtext-field/richtext-example/richtext-example.component';
import { TopicsExampleComponent } from './ipx-topics/topics-example.component';
import { IpxDevTypeaheadComponent } from './ipx-typeahead/ipx-typeahead.dev.component';
import { KendoGridDemoComponent } from './kendo-grid-demo/kendo-grid-demo.component';
import { KendoGridEditDragDropDemoComponent } from './kendo-grid-edit-dragdrop-demo/kendo-grid-edit-dragdrop-demo.component';
import { KendoGridGroupingDemoComponent } from './kendo-grid-grouping-demo/kendo-grid-grouping-demo.component';
import { PolicingTestComponent } from './kendo-grid/policing-example.component';
import { KendoGridVirtualScrollingComponent } from './kendo-virtual-scrolling/kendo-grid-virtual-scrolling.component';
import { PageTitleTestComponent } from './page/page.component.dev';
import { RadiobuttonExampleComponent } from './radiobutton/radiobutton-example.component';
import { ResizerExampleComponent } from './resizer/resizer-example.component';
import { KeyboardShortCutExampleComponent } from './shortcuts/keyboardshortcut.component';
import { StorageComponent } from './storage/storage-example.component';
import { TimePickerDevComponent } from './time-picker/time-picker.component.dev';
import { ValidatorExamplesComponent } from './validators/validator-examples/validator-examples.component';

export const policingStatusState: Ng2StateDeclaration = {
    name: 'policingStatus',
    url: '/dev/policingStatus',
    component: PolicingStatusComponent
};

export const inlineDialogState: Ng2StateDeclaration = {
    name: 'inlineDialog',
    url: '/dev/inlineDialog',
    component: InlineDialogExampleComponent
};

export const policingState: Ng2StateDeclaration = {
    name: 'policingexample',
    url: '/dev/ngpolicing',
    component: PolicingTestComponent
};

export const datePickerState: Ng2StateDeclaration = {
    name: 'ngdatepicker',
    url: '/dev/ngdatepicker',
    resolve: {}, // resolveDates
    component: DatePickerComponent
};

export const colorpickerState: Ng2StateDeclaration = {
    name: 'ipxcolorpicker',
    url: '/dev/color-picker',
    resolve: {}, // resolveDates
    component: ColorPickerExampleComponent
};

export const ipxTypeaheadState: Ng2StateDeclaration = {
    name: 'ipxTypeaheadExample',
    url: '/dev/ipx-typeahead',
    component: IpxDevTypeaheadComponent
};

export const ipxTopicsState: Ng2StateDeclaration = {
    name: 'ipxTopics',
    url: '/dev/ipx-topics',
    component: TopicsExampleComponent
};

export const pageTitleTestState: Ng2StateDeclaration = {
    name: 'ngPageTitleTest',
    url: '/dev/ngPageTitle/:id',
    params: {
        id: {
            dynamic: true,
            squash: true // it its an optional parameter
        }
    },
    resolve: {},
    component: PageTitleTestComponent
};

export const storageState: Ng2StateDeclaration = {
    name: 'storageExample',
    url: '/dev/ngStorage',
    component: StorageComponent
};

export const timePickerState: Ng2StateDeclaration = {
    name: 'timePicker',
    url: '/dev/ngTimePicker',
    component: TimePickerDevComponent
};

export const kendoGridDemoState: Ng2StateDeclaration = {
    name: 'kendoGridDemo',
    url: '/dev/kendo-grid',
    component: KendoGridDemoComponent
};

export const kendoGridGroupingDemoState: Ng2StateDeclaration = {
    name: 'kendoGridGroupingDemo',
    url: '/dev/kendo-grid-grouping',
    component: KendoGridGroupingDemoComponent
};

export const kendoGridVirtualScrollingState: Ng2StateDeclaration = {
    name: 'kendoGridVirtualScrollingDemo',
    url: '/dev/kendo-grid-virtual-scrolling',
    component: KendoGridVirtualScrollingComponent
};

export const kendoGridEditDragDropState: Ng2StateDeclaration = {
    name: 'kendoGridEditDragDropState',
    url: '/dev/kendo-grid-edit-drag-drop',
    component: KendoGridEditDragDropDemoComponent
};

export const ipxTextBoxState: Ng2StateDeclaration = {
    name: 'ipxTextBoxExamples',
    url: '/dev/ipx-textbox',
    component: IpxTextBoxExampleComponent
};
export const dropdownState: Ng2StateDeclaration = {
    name: 'ngdropdown',
    url: '/dev/dropdown',
    component: DropdownExampleComponent
};

export const checkBoxState: Ng2StateDeclaration = {
    name: 'checkBoxExample',
    url: '/dev/ipx-checkbox',
    component: CheckboxExampleComponent
};

export const radioButtonState: Ng2StateDeclaration = {
    name: 'radioButtonExample',
    url: '/dev/ipx-radiobutton',
    component: RadiobuttonExampleComponent
};

export const resizerState: Ng2StateDeclaration = {
    name: 'resizerDemo',
    url: '/dev/resizer',
    component: ResizerExampleComponent
};
export const dropdownOperatorState: Ng2StateDeclaration = {
    name: 'dropdownOperator',
    url: '/dev/dropdown-operator',
    component: DropdownOperatorExampleComponent
};

export const shortCutState: Ng2StateDeclaration = {
    name: 'shortCutDemo',
    url: '/dev/angular2shortCuts',
    component: KeyboardShortCutExampleComponent
};

export const ipxdatepickerState: Ng2StateDeclaration = {
    name: 'ipxDatePicker',
    url: '/dev/ipx-datepicker',
    component: IpxDatepickerExampleComponent
};
export const ipxdatatypeState: Ng2StateDeclaration = {
    name: 'ipxdatatype',
    url: '/dev/ipx-datatype',
    component: DataTypeExampleComponent
};
export const validatorsState: Ng2StateDeclaration = {
    name: 'validators',
    url: '/dev/validators',
    component: ValidatorExamplesComponent
};

export const dragdrop: Ng2StateDeclaration = {
    name: 'dragdrop',
    url: '/dev/drag-drop',
    component: DragDropExampleComponent
};

export const richTextFieldState: Ng2StateDeclaration = {
    name: 'ipxRichTextFieldExamples',
    url: '/dev/ipx-richtext-field',
    component: RichtextExampleComponent
};

export const kotState: Ng2StateDeclaration = {
    name: 'kot',
    url: '/dev/kot',
    component: KotPanelExampleComponent
};

export const caseAttachmentState: Ng2StateDeclaration = {
    name: 'attachments',
    url: '/dev/attachments',
    component: CaseAttachmentComponent
};

// tslint:disable-next-line:only-arrow-functions
export function getParams($transition: Transition): any {
    return {
        code: $transition.params().code
    };
}

export const resolveDates = () =>
    ({ name: {}, address: {} });
