import { Directive, ElementRef } from '@angular/core';
import { IpxKendoGridComponent } from './ipx-kendo-grid.component';

@Directive({
  selector: '[ipxGridFocus]'
})
export class GridFocusDirective {
  constructor(private readonly grid: IpxKendoGridComponent,
    private readonly el: ElementRef) { }

  focusFirstEditableField = (): void => {
    setTimeout(() => {
      this._focusFirstFieldInEditRow();
    });
  };

  focusEditableField = (colIndex?: number, focusFirst = true): void => {
    setTimeout(() => {
      if (colIndex > 0) {
        const editableField = this.el.nativeElement.querySelector(`.k-grid-edit-row > td:nth-child(${colIndex + 1}) input:not([disabled])`);
        if (!!editableField) {
          editableField.focus();

          return;
        }
      }

      if (colIndex === 0) {
        const editableField = this.el.nativeElement.querySelector('.k-grid-edit-row + tr.k-detail-row input:not([disabled])');
        if (!!editableField) {
          editableField.focus();

          return;
        }
      }

      if (focusFirst) {
        this._focusFirstFieldInEditRow();
      }
    });
  };

  private readonly _focusFirstFieldInEditRow = (): void => {
    const editableField = this.el.nativeElement.querySelector('.k-grid-edit-row input:not([disabled])');
    if (!!editableField) {
      editableField.focus();
    }
  };

  setFocusOnMasterRow = (rowIndex: number, colIndex: number): void => {
    if (rowIndex === null) {
      return;
    }
    const logicalRowIndex = rowIndex * 2 + 1; // include detail rows and header row
    this.grid.wrapper.focusCell(logicalRowIndex, colIndex > 0 ? colIndex : 0);
  };

  refocus = (): void => {
    const nav = this.grid.wrapper.focus();
    if (!nav) {
      return;
    }

    if (this.grid.currentEditRowIdx === nav.dataRowIndex) {
      const inputEle = nav.colIndex > 0
        ? this.el.nativeElement.querySelector(`.k-grid-edit-row > td:nth-child(${nav.colIndex + 1}) input`)
        : this.el.nativeElement.querySelector('.k-grid-edit-row + tr > td:last-child input');

      if (!!inputEle) {
        setTimeout(() => {
          inputEle.focus();
        });
      }
    }
  };
}