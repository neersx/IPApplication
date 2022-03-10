import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { IpxClickOutsideDirective } from './ipx-click-outside.directive';
import { IpxClickStopPropagationDirective } from './ipx-click-stop-propagation.directive';
import { IpxConfirmBeforeRouteChangeDirective } from './ipx-confirm-before-route-change.directive';
import { IpxDomChangeHandlerDirective } from './ipx-dom-change-handler.directive';
import { IpxKendoGridDragItemDirective } from './ipx-kendogrid-drag-item.directive';
import { KendoTreeDragItemDirective } from './ipx-kendotree-drag-item.directive';
import { IpxResizeHandlerDirective } from './ipx-resize-handler.directive';
import { TemplateNameDirective } from './template-name.directive';

@NgModule({
  declarations: [
    IpxClickOutsideDirective,
    IpxClickStopPropagationDirective,
    IpxResizeHandlerDirective,
    IpxKendoGridDragItemDirective,
    KendoTreeDragItemDirective,
    IpxDomChangeHandlerDirective,
    TemplateNameDirective,
    IpxConfirmBeforeRouteChangeDirective,
    IpxDomChangeHandlerDirective
  ],
  imports: [
    CommonModule
  ],
  exports: [
    IpxClickOutsideDirective,
    IpxClickStopPropagationDirective,
    IpxResizeHandlerDirective,
    IpxKendoGridDragItemDirective,
    KendoTreeDragItemDirective,
    IpxDomChangeHandlerDirective,
    TemplateNameDirective,
    IpxConfirmBeforeRouteChangeDirective,
    IpxDomChangeHandlerDirective
  ]
})
export class DirectivesModule { }
