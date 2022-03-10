import { AppContextServiceMock } from 'core/app-context.service.mock';
import { ChangeDetectorRefMock } from 'mocks';
import { Observable } from 'rxjs';
import { QuickSearchComponent } from './quick-search.component';

describe('search', () => {
  let component: QuickSearchComponent;
  let searchServiceMock;
  let stateServiceMock;
  let cdr: ChangeDetectorRefMock;
  let contextService: AppContextServiceMock;

  beforeEach(() => {
    contextService = new AppContextServiceMock();
    searchServiceMock = {
      get: jest.fn().mockReturnValue(new Observable())
    };
    stateServiceMock = { current: { name: 'caseview' }, go: () => undefined } as any;
    cdr = new ChangeDetectorRefMock();
    component = new QuickSearchComponent(
      searchServiceMock,
      stateServiceMock,
      cdr as any,
      contextService as any
    );
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('executes predictive search when typing', () => {

    const item = { id: 456, irn: 'Irn345', $highlighted: true };

    component.text = 'search';
    component.onSelect(item, null);
    expect(cdr.markForCheck).toHaveBeenCalled();
    expect(component.items).toBe(null);
    expect(component.text).toBe('Irn345');

  });

  it('execute keyboard events', () => {

    component.items = [{ id: 456, irn: 'Irn345', $highlighted: true }, { id: 125, irn: 'Irn125' }];
    component.onKeydown({ keyCode: 40 }); // down arrow
    expect(component.enterPressed).toBe(false);
    expect(component.items[0].$highlighted).toBeDefined();

    const onSelectSpy = jest.spyOn(component, 'onSelect');
    component.onKeydown({ keyCode: 13 }); // enter key when more items
    expect(cdr.markForCheck).toHaveBeenCalled();
    expect(onSelectSpy).toHaveBeenCalled();
    expect(component.enterPressed).toBe(false);

    component.items = [];
    component.onKeydown({ keyCode: 13 }); // enter key when no items
    expect(component.enterPressed).toBe(true);

    component.onKeydown({ keyCode: 27 }); // escape key
    expect(component.items).toBe(null);

    const event = { keyCode: 9, preventDefault: jest.fn().mockReturnValue(null) };
    component.onKeydown(event); // tab pressed
    expect(component.text).toBe('Irn125');
  });

  describe('search and navigate to selected case', () => {
    it('opens details of highlighted case on enter', () => {
      component.items = [
        { id: 123, irn: 'Irn123' },
        { id: 456, irn: 'Irn345', $highlighted: true }
      ];

      component.onKeydown({ keyCode: 13 });
      expect(component.enterPressed).toEqual(false);
      expect(component.text).toEqual('Irn345');
    });
  });

  describe('execute case search after ENTER when multiple records returned', () => {
    it('should search on enter', () => {
      searchServiceMock = {
        get: jest
          .fn()
          .mockReturnValue([{ id: 123, irn: 'Irn123' }, { id: 456, irn: 'Irn345' }])
      };

      component.text = 'Irn';
      const spy = jest.spyOn(searchServiceMock, 'get');
      spy.mockReturnValue(component.items);
      component.onKeydown({ keyCode: 13 });

      expect(component.text).toEqual('Irn');
      expect(component.items).not.toBe(null);
    });
  });

  describe('search and navigate to case when one record returned', () => {
    it('should navigate to case', () => {
      searchServiceMock.get([{ id: 456, irn: 'Irn345' }]);

      component.text = 'Irn345';
      component.onKeydown({ keyCode: 13 });

      expect(component.text).toEqual('Irn345');
      expect(component.items).toBe(undefined);
    });
  });

  describe('should check access for quick search', () => {
    it('should set quick search access to false if not shown in appContext ', () => {
      contextService.appContext = { user: { permissions: { canAccessQuickSearch: false } } };
      component.checkAccessLevels();

      expect(component.canAccessQuickSearch).toBe(false);
    });

    it('should set quick search access to true if available in appContext ', () => {
      contextService.appContext = { user: { permissions: { canAccessQuickSearch: true } } };
      component.checkAccessLevels();

      expect(component.canAccessQuickSearch).toBe(true);
    });
  });

});
