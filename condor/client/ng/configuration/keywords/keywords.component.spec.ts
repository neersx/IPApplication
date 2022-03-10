import { LocalSettingsMock } from 'core/local-settings.mock';
import { IpxNotificationServiceMock, NotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { BehaviorSubject, of } from 'rxjs';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { KeywordsComponent } from './keywords.component';
import { MaintainKeywordsComponent } from './maintain-keywords/maintain-keywords.component';

describe('KeywordsComponent', () => {
  let component: () => KeywordsComponent;

  const service = {
    getKeywordsList: jest.fn().mockReturnValue(of({})),
    deleteKeywords: jest.fn().mockReturnValue(of({}))
  };

  let ipxNotificationService: IpxNotificationServiceMock;
  let notificationService: NotificationServiceMock;
  let modalService: ModalServiceMock;
  let localSettings: LocalSettingsMock;

  beforeEach(() => {
    localSettings = new LocalSettingsMock();
    notificationService = new NotificationServiceMock();
    modalService = new ModalServiceMock();
    ipxNotificationService = new IpxNotificationServiceMock();
    component = () => {
      const c = new KeywordsComponent(service as any, localSettings as any, modalService as any, ipxNotificationService as any, notificationService as any);
      c.viewData = {
        canAdd: true,
        canEdit: true,
        canDelete: true
      };
      c.ngOnInit();
      c._resultsGrid = new IpxKendoGridComponentMock();
      c._resultsGrid.wrapper = {
        data: [
          { keywordNo: '1', keyword: 'abc' },
          { keywordNo: '2', keyword: 'xyz' }
        ]
      } as any;

      return c;
    };
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should initialise', () => {
    const c = component();
    spyOn(c, 'buildGridOptions');

    expect(c.gridOptions).toBeDefined();
    expect(c.gridOptions.columns.length).toBe(3);
    expect(c.gridOptions.columns[0].title).toBe('keywords.column.keyword');
    expect(c.gridOptions.columns[0].field).toBe('keyWord');
  });

  it('should clear search text', () => {
    const c = component();
    c.ngOnInit();
    c.searchText = 'abc';
    c.gridOptions = { _search: jest.fn().mockReturnValue({}), read$: jest.fn(), columns: [] };
    c.clear();
    expect(c.searchText).toBe('');
    expect(c.gridOptions._search).toHaveBeenCalled();
  });

  it('should open modal on onRowAddedOrEdited', () => {

    const c = component();
    modalService.openModal.mockReturnValue({
      content: {
        addedRecordId$: new BehaviorSubject(true),
        onClose$: new BehaviorSubject(true)
      }
    });
    c._resultsGrid.wrapper.data = {
      data: [{
        id: 1,
        status: 'A'
      }]
    };
    const data = { dataItem: { id: 1, status: 'A' } };
    c.onRowAddedOrEdited(data, 'Add');
    expect(modalService.openModal).toHaveBeenCalled();
  });

  describe('Filter search', () => {
    it('should call search grid on search click', () => {
      const c = component();
      c.gridOptions._search = jest.fn();
      c.search();
      expect(c.gridOptions._search).toBeCalled();
    });

    it('should clear default values of filter', () => {
      const c = component();
      c.gridOptions._search = jest.fn();
      c.searchText = 'ABC';
      c.clear();
      expect(c.searchText).toBe('');
      expect(c.gridOptions._search).toBeCalled();
    });
  });

  describe('delete keywords', () => {
    beforeEach(() => {
      const c = component();
      c.ngOnInit();
      c._resultsGrid.getRowSelectionParams().allSelectedItems = [{ key: 1 }, { key: 2 }];
      c.gridOptions = { _search: jest.fn().mockReturnValue({}), read$: jest.fn(), columns: [] };
      ipxNotificationService.openDeleteConfirmModal = jest.fn().mockReturnValue({ content: { confirmed$: of(true), cancelled$: of(true) } });
    });

    it('should not return notification when selected records are deleted', () => {
      const c = component();
      service.deleteKeywords = jest.fn().mockReturnValue(of());
      c.deleteKeywords([1, 2]);
      expect(service.deleteKeywords).toHaveBeenCalledWith([1, 2]);
    });
  });

  describe('AddEditKeywords', () => {
    beforeEach(() => {
      const c = component();
      c.ngOnInit();
      modalService.openModal.mockReturnValue({
        content: {
          onClose$: new BehaviorSubject(true),
          addedRecordId$: new BehaviorSubject(0)
        }
      });
      c._resultsGrid.getRowSelectionParams().rowSelection = [1];
    });
    it('should handle row add correctly', () => {
      const c = component();
      c.onRowAddedOrEdited(undefined, 'A');
      expect(modalService.openModal).toHaveBeenCalledWith(MaintainKeywordsComponent,
        {
          animated: false,
          backdrop: 'static',
          class: 'modal-lg',
          initialState: {
            isAdding: true,
            id: undefined
          }
        });
    });

    it('should handle row edit correctly', () => {
      const c = component();
      c.onRowAddedOrEdited(1, 'E');
      expect(modalService.openModal).toHaveBeenCalledWith(MaintainKeywordsComponent,
        {
          animated: false,
          backdrop: 'static',
          class: 'modal-lg',
          initialState: {
            isAdding: false,
            id: 1
          }
        });
    });
  });
});
