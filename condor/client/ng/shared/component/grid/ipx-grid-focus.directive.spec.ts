/* tslint:disable:no-unused-variable */
import { fakeAsync, tick } from '@angular/core/testing';
import { ElementRefMock } from 'mocks';
import { GridFocusDirective } from './ipx-grid-focus.directive';
import { IpxKendoGridComponentMock } from './ipx-kendo-grid.component.mock';

describe('Directive: IpxGridFocus', () => {
  let grid: IpxKendoGridComponentMock;
  let el: ElementRefMock;
  let directive: GridFocusDirective;

  beforeEach(() => {
    grid = new IpxKendoGridComponentMock();
    el = new ElementRefMock();

    directive = new GridFocusDirective(grid as any, el as any);
  });

  it('should create an instance', () => {
    expect(directive).toBeTruthy();
  });

  describe('refocus', () => {
    it('should call grid to focus on last active cell', () => {
      directive.refocus();
      expect(grid.wrapper.focus).toHaveBeenCalled();
    });

    it('should get input element inside cell and try focus, if active cell is in editable row', fakeAsync(() => {
      grid.wrapper.focus = jest.fn().mockReturnValue({ dataRowIndex: 1, colIndex: 1 });
      grid.currentEditRowIdx = 1;
      const inputEle = { focus: jest.fn() };
      el.nativeElement.querySelector = jest.fn().mockReturnValue(inputEle);

      directive.refocus();
      tick();

      expect(el.nativeElement.querySelector).toHaveBeenCalled();
      expect(inputEle.focus).toHaveBeenCalled();
    }));
  });

  describe('setFocusOnMasterRow', () => {
    it('does not call focus cell if row null', () => {
      directive.setFocusOnMasterRow(null, 10);
      expect(grid.wrapper.focusCell).not.toHaveBeenCalled();
    });

    it('calls focus cell with logical row index and cell index', () => {
      directive.setFocusOnMasterRow(10, 10);
      expect(grid.wrapper.focusCell).toHaveBeenCalledWith(21, 10);

      directive.setFocusOnMasterRow(10, null);
      expect(grid.wrapper.focusCell).toHaveBeenCalledWith(21, 0);
    });
  });

  describe('focusEditableField', () => {
    it('should set focus on the provided column index', fakeAsync(() => {
      const innerElem = { focus: jest.fn() };
      el.nativeElement.querySelector = jest.fn().mockReturnValue(innerElem);
      directive.focusEditableField(4, false);
      tick();
      expect(el.nativeElement.querySelector).toHaveBeenCalled();
      expect(el.nativeElement.querySelector.mock.calls[0][0].includes('td:nth-child(5)')).toBeTruthy();
      expect(innerElem.focus).toHaveBeenCalled();
    }));

    it('should set focus on the details row element', fakeAsync(() => {
      const innerElem = { focus: jest.fn() };
      el.nativeElement.querySelector = jest.fn().mockReturnValue(innerElem);
      directive.focusEditableField(0, false);
      tick();
      expect(el.nativeElement.querySelector).toHaveBeenCalled();
      expect(el.nativeElement.querySelector.mock.calls[0][0].includes('tr.k-detail-row')).toBeTruthy();
      expect(innerElem.focus).toHaveBeenCalled();
    }));

    it('should set focus on the first element in the row, as fallback', fakeAsync(() => {
      const innerElem = { focus: jest.fn() };
      el.nativeElement.querySelector = jest.fn().mockReturnValue(innerElem);
      directive.focusEditableField(-1, true);
      tick();
      expect(el.nativeElement.querySelector).toHaveBeenCalled();
      expect(el.nativeElement.querySelector.mock.calls[0][0].includes('.k-grid-edit-row input')).toBeTruthy();
      expect(innerElem.focus).toHaveBeenCalled();
    }));

    it('should not focus on any element if condtions are not met', fakeAsync(() => {
      el.nativeElement.querySelector = jest.fn().mockReturnValue(null);
      directive.focusEditableField(-1, false);
      tick();
      expect(el.nativeElement.querySelector).not.toHaveBeenCalled();
    }));
  });

  describe('focusFirstEditableField', () => {
    it('should set focus on the first editable element in the row under edit', fakeAsync(() => {
      const innerElem = { focus: jest.fn() };
      el.nativeElement.querySelector = jest.fn().mockReturnValue(innerElem);
      directive.focusFirstEditableField();
      tick();
      expect(el.nativeElement.querySelector).toHaveBeenCalled();
      expect(el.nativeElement.querySelector.mock.calls[0][0].includes('.k-grid-edit-row input')).toBeTruthy();
      expect(innerElem.focus).toHaveBeenCalled();
    }));
  });
});
