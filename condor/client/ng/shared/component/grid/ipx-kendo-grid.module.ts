
import { NgModule } from '@angular/core';
import { GridModule } from '@progress/kendo-angular-grid';
import { ContextMenuModule } from '@progress/kendo-angular-menu';
import { PopoverModule } from 'ngx-bootstrap/popover';
import { BaseCommonModule } from 'shared/base.common.module';
import { DirectivesModule } from 'shared/directives/directives.module';
import { ButtonsModule } from '../buttons/buttons.module';
import { FormControlsModule } from '../forms/form-controls.module';
import { NotificationModule } from '../notification/notification.module';
import { TooltipModule } from '../tooltip/tooltip.module';
import { UtilityModule } from '../utility/utility.module';
import { ApplyColSpanDirective } from './apply-colspan.directive';
import { BulkActionsMenuComponent } from './bulkactions/ipx-bulk-actions-menu.component';
import { IpxGridColumnPickerComponent } from './column-picker/ipx-grid-colum-picker';
import { IpxGridColumnListComponent } from './column-picker/ipx-grid-column-list';
import { MultiCheckFilterComponent } from './filters/ipx-grid-multicheck-filter.component';
import { EditorDirective } from './ipx-editor.directive';
import { IpxGridDataBindingDirective } from './ipx-grid-data-binding.directive';
import { GridFocusDirective } from './ipx-grid-focus.directive';
import { IpxKendoGridComponent } from './ipx-kendo-grid.component';
import { MouseKeyboardEventHandlerDirective } from './ipx-mouse-keyboard-event-handler.directive';
import { EditTemplateColumnFieldDirective, TemplateColumnFieldDirective } from './ipx-template-column-field.directive';
import { GridToolbarComponent } from './toolbar/grid-toolbar.component';

@NgModule({
   imports: [
      BaseCommonModule,
      GridModule,
      FormControlsModule,
      UtilityModule,
      ButtonsModule,
      DirectivesModule,
      NotificationModule,
      ContextMenuModule,
      PopoverModule,
      TooltipModule
   ],
   declarations: [
      IpxKendoGridComponent,
      IpxGridDataBindingDirective,
      TemplateColumnFieldDirective,
      EditTemplateColumnFieldDirective,
      IpxGridColumnPickerComponent,
      IpxGridColumnListComponent,
      MultiCheckFilterComponent,
      GridToolbarComponent,
      EditorDirective,
      BulkActionsMenuComponent,
      MouseKeyboardEventHandlerDirective,
      GridFocusDirective,
      ApplyColSpanDirective
   ],
   exports: [
      GridModule,
      IpxKendoGridComponent,
      IpxGridDataBindingDirective,
      TemplateColumnFieldDirective,
      EditTemplateColumnFieldDirective,
      MultiCheckFilterComponent,
      GridToolbarComponent,
      IpxGridColumnPickerComponent,
      IpxGridColumnListComponent,
      EditorDirective,
      BulkActionsMenuComponent,
      MouseKeyboardEventHandlerDirective,
      GridFocusDirective,
      ApplyColSpanDirective
   ]
})
export class IpxKendoGridModule { }
