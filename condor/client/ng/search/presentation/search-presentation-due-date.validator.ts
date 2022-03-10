import { Injectable } from '@angular/core';
import * as _ from 'underscore';
import { DueDateValidator, PresentationColumnView } from './search-presentation.model';

@Injectable()
export class DueDateColumnsValidator {
    allDatesColumns: Array<string> = ['DATESCYCLEANY', 'DATESDESCANY', 'DATESDUEANY', 'DATESEVENTANY', 'DATESTEXTANYOFTYPE', 'DATESTEXTANYOFTYPEMODIFIEDDATE'];

    validate = (isExternal: Boolean, selectedColumns: Array<PresentationColumnView>): DueDateValidator => {
        const groupKey = isExternal ? -45 : -44;
        const hasDueDateColumn = _.any(selectedColumns, sc => {
          return sc.groupKey === groupKey;
        });
        const hasAllDateColumn = _.any(selectedColumns, sc => {
          return sc.procedureItemId && _.contains(this.allDatesColumns, sc.procedureItemId.toUpperCase());
        });

        return {
            hasDueDateColumn,
            hasAllDateColumn
        };
      };
}