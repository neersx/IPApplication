import { LocalSettingsMock } from 'core/local-settings.mock';
import { IpxGridOptionsMock, Renderer2Mock, RoleSearchMock } from 'mocks';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { RolesTasksComponent } from './roles-tasks.component';
describe('RolesTasksComponent', () => {
    let c: RolesTasksComponent;
    const service = new RoleSearchMock();
    const renderer = new Renderer2Mock();
    const gridoptionsMock = new IpxGridOptionsMock();
    const localSettings = new LocalSettingsMock();
    beforeEach(() => {
        c = new RolesTasksComponent(renderer as any, service as any, localSettings as any);
        c.gridOptions = new IpxGridOptionsMock() as any;
        c._resultsGrid = new IpxKendoGridComponentMock() as any;
        c.resultsGrid = new IpxKendoGridComponentMock() as any;
        c.topic = {
            params: {
                viewData: {
                    roleId: 1
                }
            }
        } as any;
    });
    it('should initialize RolesTasksComponent', () => {
        expect(c).toBeTruthy();
    });

    it('should call ngOnInit', () => {
        c.ngOnInit();
        expect(c.gridOptions.columns.length).toEqual(9);
        expect(c.showDescriptionColumn).toEqual(false);
        expect(c.showOnlyPermissionSet).toEqual(false);
    });
    it('should call onSearch', () => {
        const searchValue = { value: '1' };
        c.gridOptions = gridoptionsMock;
        spyOn(gridoptionsMock, '_search').and.returnValue([]);
        spyOn(c.searchClicked, 'next');
        c.onSearch(searchValue);
        expect(c.searchValue).toEqual('1');
        expect(c.searchClicked.next).toHaveBeenCalled();
    });
    it('should call onClear', () => {
        c.searchValue = '1';
        c.gridOptions = gridoptionsMock;
        spyOn(gridoptionsMock, '_search').and.returnValue([]);
        spyOn(c.searchClicked, 'next');
        c.onClear();
        expect(c.searchValue).toEqual('');
        expect(c.searchClicked.next).toHaveBeenCalled();
    });
    it('should call onFilterchanged', () => {
        spyOn(c.hasFilterChanged, 'next');
        c.onFilterchanged();
        expect(c.hasFilterChanged.next).toHaveBeenCalled();
    });
    it('should call revert', () => {
        c.revert();
        expect(c.isGridDirty).toEqual(false);
        expect(c.permissonChangedList).toEqual([]);
    });
    it('should call onValueChanged', () => {
        c.permissonChangedList = [];
        let dataitem = {
            taskKey: 71
        };
        c.onValueChanged(dataitem);
        expect(c.permissonChangedList.length).toEqual(1);
        expect(c.isGridDirty).toEqual(true);
        c.permissonChangedList = [{
            taskKey: 71
        }];
        dataitem = {
            taskKey: 71
        };
        c.onValueChanged(dataitem);
        expect(c.permissonChangedList.length).toEqual(1);
    });
    it('should call makeActionList with executePermission for Modified', () => {
        c.makeActionList();
        c.persistTaskList = [{
            taskKey: 71,
            state: null,
            executePermission: 1,
            isExecuteApplicable: 1
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            executePermission: 2,
            isExecuteApplicable: 1
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Modified');
    });

    it('should call makeActionList with executePermission for Added', () => {
        c.makeActionList();
        c.persistTaskList = [{
            taskKey: 71,
            state: null,
            executePermission: null,
            isExecuteApplicable: 1
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            executePermission: 2,
            isExecuteApplicable: 1
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Added');
    });

    it('should call makeActionList with executePermission for Deleted', () => {
        c.makeActionList();
        c.persistTaskList = [{
            taskKey: 71,
            state: null,
            executePermission: 1,
            isExecuteApplicable: 1
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            executePermission: 0,
            isExecuteApplicable: 1
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Deleted');
    });
    it('should call makeActionList with Insert, Update and Delete Permission for Added', () => {
        c.makeActionList();
        c.persistTaskList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 0,
            isInsertApplicable: 1,
            isDeleteApplicable: 1,
            isUpdateApplicable: 1,
            insertPermission: null,
            deletePermission: null,
            updatePermission: null
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 0,
            isInsertApplicable: 1,
            isDeleteApplicable: 1,
            isUpdateApplicable: 1,
            insertPermission: 1,
            deletePermission: 1,
            updatePermission: 1
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Added');
        expect(c.permissonChangedList[0].objectTable).toEqual('TASK');
    });
    it('should call makeActionList with Insert, Update and Delete Permission for modified', () => {
        c.makeActionList();
        c.persistTaskList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 0,
            isInsertApplicable: 1,
            isDeleteApplicable: 1,
            isUpdateApplicable: 1,
            insertPermission: 2,
            deletePermission: 2,
            updatePermission: 2
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 0,
            isInsertApplicable: 1,
            isDeleteApplicable: 1,
            isUpdateApplicable: 1,
            insertPermission: 1,
            deletePermission: 1,
            updatePermission: 1
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Modified');
        expect(c.permissonChangedList[0].objectTable).toEqual('TASK');
    });

    it('should call makeActionList with Insert, Update and Delete Permission for Deleted', () => {
        c.makeActionList();
        c.persistTaskList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 0,
            isInsertApplicable: 1,
            isDeleteApplicable: 1,
            isUpdateApplicable: 1,
            insertPermission: 2,
            deletePermission: 2,
            updatePermission: 2
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 0,
            isInsertApplicable: 1,
            isDeleteApplicable: 1,
            isUpdateApplicable: 1,
            insertPermission: 0,
            deletePermission: 0,
            updatePermission: 0
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Deleted');
        expect(c.permissonChangedList[0].objectTable).toEqual('TASK');
    });

    it('should call makeActionList with Execute, Insert, Update and Delete Permission for Added', () => {
        c.makeActionList();
        c.persistTaskList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 1,
            isInsertApplicable: 1,
            isDeleteApplicable: 1,
            isUpdateApplicable: 1,
            insertPermission: null,
            deletePermission: null,
            updatePermission: null,
            executePermission: null
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 1,
            isInsertApplicable: 1,
            isDeleteApplicable: 1,
            isUpdateApplicable: 1,
            insertPermission: 1,
            deletePermission: 1,
            updatePermission: 1,
            executePermission: 1
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Added');
        expect(c.permissonChangedList[0].objectTable).toEqual('TASK');
    });
    it('should call makeActionList with Execute, Insert, Update and Delete Permission for Modified', () => {
        c.makeActionList();
        c.persistTaskList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 1,
            isInsertApplicable: 1,
            isDeleteApplicable: 1,
            isUpdateApplicable: 1,
            insertPermission: 2,
            deletePermission: 2,
            updatePermission: 2,
            executePermission: 2
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 1,
            isInsertApplicable: 1,
            isDeleteApplicable: 1,
            isUpdateApplicable: 1,
            insertPermission: 1,
            deletePermission: 1,
            updatePermission: 1,
            executePermission: 1
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Modified');
        expect(c.permissonChangedList[0].objectTable).toEqual('TASK');
    });
    it('should call makeActionList with Execute, Insert, Update and Delete Permission for Deleted', () => {
        c.makeActionList();
        c.persistTaskList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 1,
            isInsertApplicable: 1,
            isDeleteApplicable: 1,
            isUpdateApplicable: 1,
            insertPermission: 2,
            deletePermission: 2,
            updatePermission: 2,
            executePermission: 2
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 1,
            isInsertApplicable: 1,
            isDeleteApplicable: 1,
            isUpdateApplicable: 1,
            insertPermission: 0,
            deletePermission: 0,
            updatePermission: 0,
            executePermission: 0
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Deleted');
        expect(c.permissonChangedList[0].objectTable).toEqual('TASK');
    });

    it('should call makeActionList with Update Permission for Added', () => {
        c.makeActionList();
        c.persistTaskList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 0,
            isInsertApplicable: 0,
            isDeleteApplicable: 0,
            isUpdateApplicable: 1,
            insertPermission: null,
            deletePermission: null,
            updatePermission: null,
            executePermission: null
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 0,
            isInsertApplicable: 0,
            isDeleteApplicable: 0,
            isUpdateApplicable: 1,
            insertPermission: 1,
            deletePermission: 1,
            updatePermission: 1,
            executePermission: 1
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Added');
        expect(c.permissonChangedList[0].objectTable).toEqual('TASK');
    });
    it('should call makeActionList with Update Permission for Modified', () => {
        c.makeActionList();
        c.persistTaskList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 0,
            isInsertApplicable: 0,
            isDeleteApplicable: 0,
            isUpdateApplicable: 1,
            insertPermission: null,
            deletePermission: null,
            updatePermission: 1,
            executePermission: null
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 0,
            isInsertApplicable: 0,
            isDeleteApplicable: 0,
            isUpdateApplicable: 1,
            insertPermission: 1,
            deletePermission: 1,
            updatePermission: 2,
            executePermission: 1
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Modified');
        expect(c.permissonChangedList[0].objectTable).toEqual('TASK');
    });
    it('should call makeActionList with Update Permission for Deleted', () => {
        c.makeActionList();
        c.persistTaskList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 0,
            isInsertApplicable: 0,
            isDeleteApplicable: 0,
            isUpdateApplicable: 1,
            insertPermission: null,
            deletePermission: null,
            updatePermission: 1,
            executePermission: null
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            isExecuteApplicable: 0,
            isInsertApplicable: 0,
            isDeleteApplicable: 0,
            isUpdateApplicable: 1,
            insertPermission: 1,
            deletePermission: 1,
            updatePermission: 0,
            executePermission: 1
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Deleted');
        expect(c.permissonChangedList[0].objectTable).toEqual('TASK');
    });
});
