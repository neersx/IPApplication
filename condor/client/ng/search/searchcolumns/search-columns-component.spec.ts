import { IpxGridOptionsMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { Observable } from 'rxjs';
import { SearchColumnsComponent } from './search-columns-component';
describe('SearchColumnsComponent', () => {
    let component: SearchColumnsComponent;
    let searchColumnsService: any;
    let translateServiceMock: any;
    const modalService = new ModalServiceMock();
    const notificationServiceMock = new NotificationServiceMock();
    let gridoptionsMock;
    let ipxKendoGridComponent;
    beforeEach(() => {
        searchColumnsService = { deleteSearchColumns: jest.fn().mockReturnValue(new Observable()) };
        ipxKendoGridComponent = {
            allSelectedItems: [
                {
                    dataItemId: 51,
                    contextId: 2,
                    displayName: 'Acceptance Date',
                    columnNameDescription: 'The date the case was accepted',
                    columnId: 15,
                    inUse: true,
                    saved: false,
                    selected: true
                },
                {
                    dataItemId: 31,
                    contextId: 2,
                    displayName: 'Agent',
                    columnNameDescription: 'The name of the Agent.',
                    columnId: -92,
                    inUse: true,
                    saved: false,
                    selected: true
                }
            ],
            rowSelectionChanged: jest.fn().mockReturnValue(new Observable()),
            resetSelection: jest.fn(),
            getSelectedItems: jest.fn().mockReturnValue([])
        };
        translateServiceMock = new TranslateServiceMock();
        gridoptionsMock = new IpxGridOptionsMock();
        component = new SearchColumnsComponent(searchColumnsService, translateServiceMock, modalService as any, notificationServiceMock as any);
        component.viewData = {
            queryContextKey: 1,
            queryContextPermissions: [
                {
                    queryContext: 2,
                    queryContextType: 'internal',
                    displayForInternal: false,
                    canCreateSearchColumn: false,
                    canUpdateSearchColumn: false,
                    canDeleteSearchColumn: false
                },
                {
                    queryContext: 1,
                    queryContextType: 'external',
                    displayForInternal: true,
                    canCreateSearchColumn: true,
                    canUpdateSearchColumn: true,
                    canDeleteSearchColumn: true
                }
            ]
        };
    });

    it('should initialize SearchColumnsComponent', () => {
        expect(component).toBeTruthy();
    });

    it('should call getSearchName method for case', () => {
        component.setSearchName(1);
        expect(component.searchName).toEqual('SearchColumns.case');
    });

    it('should call getSearchName method for nameSearch', () => {
        component.setSearchName(10);
        expect(component.searchName).toEqual('SearchColumns.name');
    });

    it('should call getSearchName method for wipOverview', () => {
        component.setSearchName(200);
        expect(component.searchName).toEqual('SearchColumns.wipOverview');
    });

    it('should call getSearchName method for activitySearchColumns', () => {
        component.setSearchName(190);
        expect(component.searchName).toEqual('SearchColumns.activitySearchColumns');
    });

    it('should call search', () => {
        component.gridOptions = gridoptionsMock;
        spyOn(gridoptionsMock, '_search').and.returnValue([]);
        component.gridOptions._search();
        expect(component.gridOptions._search).toBeCalled();
    });

    it('should call clear', () => {
        component.searchCriteria = {};
        component.searchCriteria.text = 'code';
        component.gridOptions = gridoptionsMock;
        spyOn(gridoptionsMock, '_search').and.returnValue([]);
        component.clear();
        expect(component.gridOptions._search).toBeCalled();
        expect(component.searchCriteria.text).toEqual('');
    });

    it('should call toggleFilterOption', () => {
        component.searchCriteria = {};
        component.gridOptions = gridoptionsMock;
        spyOn(gridoptionsMock, '_search').and.returnValue([]);
        component.searchColumnGrid = ipxKendoGridComponent;
        component.toggleFilterOption(1);
        expect(component.gridOptions._search).toBeCalled();
        expect(component.searchCriteria.queryContextKey).toEqual(1);
    });

    it('should call deleteSelectedColumns method', () => {
        component.searchColumnGrid = ipxKendoGridComponent;
        component.filterValue = { internalContext: 1, externalContext: 2, displayForInternal: true };
        component.deleteSelectedColumns();
        expect(searchColumnsService.deleteSearchColumns).toBeCalled();
    });

    it('should call getCurrentContext method', () => {
        component.filterValue = { internalContext: 1, externalContext: 2, displayForInternal: true };
        const value = component.getCurrentContext();
        expect(value).toEqual(1);
    });

    it('should call openModal method', () => {
        component.filterValue = { internalContext: 1, externalContext: 2, displayForInternal: true };
        const columnId = 1;
        const state = 'adding';
        component.openModal(columnId, state);
        expect(modalService.openModal).toBeCalled();
    });

    it('should call getSearchName method for bill search', () => {
        component.setSearchName(451);
        expect(component.searchName).toEqual('SearchColumns.billSearch.title');
    });
});