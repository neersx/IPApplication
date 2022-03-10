import { ElementRefMock, Renderer2Mock } from 'mocks';
import { EnterPressedEvent } from './ipx-grid.models';
import { IpxKendoGridComponentMock } from './ipx-kendo-grid.component.mock';
import { MouseKeyboardEventHandlerDirective } from './ipx-mouse-keyboard-event-handler.directive';

describe('Directive: InCellTab', () => {
  let grid: IpxKendoGridComponentMock;
  let el: ElementRefMock;
  let renderer: Renderer2Mock;
  let directive: MouseKeyboardEventHandlerDirective;

  beforeEach(() => {
    grid = new IpxKendoGridComponentMock();
    el = new ElementRefMock();
    renderer = new Renderer2Mock();

    directive = new MouseKeyboardEventHandlerDirective(grid as any, el, renderer as any);
  });

  it('should create an instance', () => {
    expect(directive).toBeTruthy();
  });

  it('should listen to keydown', () => {
    directive.ngOnInit();
    expect(renderer.listen).toHaveBeenCalled();
  });

  describe('handleTabForDateInput', () => {
    it('should worry about tab only, active row only and kendo time picker only', () => {
      const event: KeyboardEvent = { key: 'a' } as any;
      grid.wrapper = { activeRow: { dataItem: 'Wow' } };

      directive.onKeydown(event);
      expect(el.nativeElement.querySelector).not.toHaveBeenCalled();

      const eventTab: KeyboardEvent = { key: 'Tab' } as any;
      directive.onKeydown(eventTab);
      expect(el.nativeElement.querySelector).toHaveBeenCalled();
    });

    it('should worry about active row only', () => {
      const event: KeyboardEvent = { key: 'Tab' } as any;

      grid.wrapper = {};
      directive.onKeydown(event);
      expect(el.nativeElement.querySelector).not.toHaveBeenCalled();

      grid.wrapper = { activeRow: null };
      directive.onKeydown(event);
      expect(el.nativeElement.querySelector).not.toHaveBeenCalled();

      grid.wrapper = { activeRow: { dataItem: null } };
      directive.onKeydown(event);
      expect(el.nativeElement.querySelector).not.toHaveBeenCalled();

      grid.wrapper = { activeRow: { dataItem: 'Yuppiee' } };
      directive.onKeydown(event);
      expect(el.nativeElement.querySelector).toHaveBeenCalled();
    });

    it('should call prev or next based on shift key selection', () => {
      grid.wrapper = { activeRow: { dataItem: 'Yuppiee' }, focusPrevCell: jest.fn(), focusNextCell: jest.fn() };

      const event: KeyboardEvent = { key: 'Tab', shiftKey: false } as any;
      el.nativeElement.querySelector = jest.fn().mockReturnValue('yes I have Kendo time pickers');

      directive.onKeydown(event);
      expect(grid.wrapper.focusNextCell).toHaveBeenCalled();

      const eventShift = { key: 'Tab', shiftKey: true } as any;
      directive.onKeydown(eventShift);
      expect(grid.wrapper.focusPrevCell).toHaveBeenCalled();
    });

    it('if next cell selected, try to put focus on input element inside', () => {
      grid.wrapper = { activeRow: { dataItem: 'Yuppiee' }, focusNextCell: jest.fn().mockReturnValueOnce('someControl') };

      const event: KeyboardEvent = { key: 'Tab', shiftKey: false, preventDefault: jest.fn() } as any;
      const inputEle = { focus: jest.fn() };
      el.nativeElement.querySelector = jest.fn().mockReturnValueOnce('yes I have Kendo time pickers').mockReturnValueOnce(inputEle);

      directive.onKeydown(event);
      expect(inputEle.focus).toHaveBeenCalled();
      expect(event.preventDefault).toHaveBeenCalled();
    });
  });

  describe('enter', () => {
    beforeEach(() => {
      grid.wrapper = { activeRow: { dataItem: { a: 'a' } } };
    });
    it('should raise event if cell is clicked', () => {
      el.nativeElement.querySelector = jest.fn();
      const event: KeyboardEvent = { key: 'Enter' } as any;
      grid.wrapper = { activeCell: null };

      directive.onKeydown(event);

      expect(el.nativeElement.querySelector).not.toHaveBeenCalled();
    });

    it('should raise event if row is clicked', done => {
      const currentRowEle = {
        classList: {
          contains: jest.fn().mockReturnValue(true)
        }
      };
      el.nativeElement.querySelectorAll = jest.fn().mockReturnValue([currentRowEle]);
      const event: KeyboardEvent = { key: 'Enter' } as any;
      grid.wrapper = { ...grid.wrapper, activeCell: { dataRowIndex: 0, dataItem: 'something' } };
      directive.onEnter.subscribe((d: EnterPressedEvent) => {
        expect(d.dataItem).toBe('something');
        expect(d.rowState.isExpanded).toBe(true);
        expect(d.rowState.isInEditMode).toBe(true);

        done();
      });

      directive.onKeydown(event);

      expect(el.nativeElement.querySelectorAll).toHaveBeenCalled();
    });

    it('should pass relavent details in raised event', done => {
      const currentRowEle = {
        classList: {
          contains: jest.fn().mockReturnValue(false)
        }
      };

      el.nativeElement.querySelectorAll = jest.fn().mockReturnValueOnce([null, currentRowEle]).mockReturnValueOnce(true);
      const event: KeyboardEvent = { key: 'Enter' } as any;
      grid.wrapper = { ...grid.wrapper, activeCell: { dataRowIndex: 1, dataItem: 'something' } };
      directive.onEnter.subscribe((d: EnterPressedEvent) => {
        expect(d.dataItem).toBe('something');
        expect(d.rowState.isExpanded).toBe(false);
        expect(d.rowState.isInEditMode).toBe(false);

        done();
      });

      directive.onKeydown(event);

      expect(el.nativeElement.querySelectorAll).toHaveBeenCalled();
    });
  });
});
