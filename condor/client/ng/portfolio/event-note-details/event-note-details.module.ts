import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { BaseCommonModule } from 'shared/base.common.module';
import { FormControlsModule } from 'shared/component/forms/form-controls.module';
import { IpxKendoGridModule } from 'shared/component/grid/ipx-kendo-grid.module';
import { SharedModule } from 'shared/shared.module';
import { IpxTypeaheadModule } from './../../shared/component/typeahead/typeahead.module';
import { EventNoteDetailsComponent } from './event-note-details.component';
import { EventNoteDetailsService } from './event-note-details.service';

const components = [
    EventNoteDetailsComponent
];

@NgModule({
    declarations: [
        ...components
    ],
    imports: [
      SharedModule
    ],
    providers: [EventNoteDetailsService],
    exports: [
      ...components
    ]
  })
  export class EventNoteDetailsModule { }