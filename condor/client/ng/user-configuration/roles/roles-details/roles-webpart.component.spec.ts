import { IpxGridOptionsMock, Renderer2Mock, RoleSearchMock } from 'mocks';
import { RolesWebPartComponent } from './roles-webpart.component';
describe('RolesWebPartComponent', () => {
    let c: RolesWebPartComponent;
    const service = new RoleSearchMock();
    let viewData: any;
    beforeEach(() => {
        c = new RolesWebPartComponent(service as any);
        viewData = {
            roleId: 1
        };
        c.topic = {
            params: {
                viewData
            },
            key: 'Status',
            title: 'Status'
        };
    });
    it('should initialize RolesWebPartComponent', () => {
        expect(c).toBeTruthy();
    });

    it('should call ngOnInit', () => {
        c.ngOnInit();
        expect(c.gridOptions.columns.length).toEqual(6);
    });

    it('should call onFilterchanged', () => {
        spyOn(c.hasFilterChanged, 'next');
        c.onFilterchanged();
        expect(c.hasFilterChanged.next).toHaveBeenCalled();
    });

    it('should call revert method', () => {
        c.revert();
        expect(c.isGridDirty).toEqual(false);
        expect(c.permissonChangedList).toEqual([]);
    });
    it('should call isDirty method', () => {
        c.isDirty();
        expect(c.isGridDirty).toEqual(false);
    });
    it('should call onValueChanged method', () => {
        c.permissonChangedList = [];
        let dataitem = {
            taskKey: 71
        };
        c.onValueChanged(dataitem, 's');
        expect(c.permissonChangedList.length).toEqual(1);
        expect(c.isGridDirty).toEqual(true);
        c.permissonChangedList = [{
            taskKey: 71
        }];
        dataitem = {
            taskKey: 71
        };
        c.onValueChanged(dataitem, 'm');
        expect(c.permissonChangedList.length).toEqual(1);
        expect(c.isGridDirty).toEqual(true);
    });
    it('should call makeActionList for modify', () => {
        c.makeActionList();
        c.persistWebpartList = [{
            taskKey: 71,
            state: null,
            selectPermission: 1,
            mandatoryPermission: 1
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            selectPermission: 2,
            mandatoryPermission: 2,
            oldselectPermission: 0,
            oldMandatoryPermission: 0
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Modified');
        expect(c.permissonChangedList[0].objectTable).toEqual('MODULE');
    });
    it('should call makeActionList for added', () => {
        c.makeActionList();
        c.persistWebpartList = [{
            taskKey: 71,
            state: null,
            selectPermission: null,
            mandatoryPermission: null
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            selectPermission: 2,
            mandatoryPermission: 1,
            oldselectPermission: 0,
            oldMandatoryPermission: 0
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Added');
        expect(c.permissonChangedList[0].objectTable).toEqual('MODULE');
    });

    it('should call makeActionList for deleted', () => {
        c.makeActionList();
        c.persistWebpartList = [{
            taskKey: 71,
            state: null,
            selectPermission: 1,
            mandatoryPermission: 2
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            selectPermission: 0,
            mandatoryPermission: 0
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Deleted');
        expect(c.permissonChangedList[0].objectTable).toEqual('MODULE');
    });
});