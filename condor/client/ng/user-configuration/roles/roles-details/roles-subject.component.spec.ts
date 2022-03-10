import { RoleSearchMock } from 'mocks';
import { RolesSubjectComponent } from './roles-subject.component';
describe('RolesSubjectComponent', () => {
    let c: RolesSubjectComponent;
    const service = new RoleSearchMock();
    let viewData: any;
    beforeEach(() => {
        c = new RolesSubjectComponent(service as any);
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
    it('should initialize RolesSubjectComponent', () => {
        expect(c).toBeTruthy();
    });

    it('should call ngOnInit', () => {
        c.ngOnInit();
        expect(c.gridOptions.columns.length).toEqual(3);
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
        expect(c.isGridDirty).toEqual(true);
    });

    it('should call makeActionList Modified', () => {
        c.makeActionList();
        c.persistSubjectList = [{
            taskKey: 71,
            state: null,
            selectPermission: 1,
            isExecuteApplicable: 1
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            selectPermission: 2,
            oldselectPermission: null,
            isExecuteApplicable: 1
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Modified');
        expect(c.permissonChangedList[0].objectTable).toEqual('DATATOPIC');
    });
    it('should call makeActionList Added', () => {
        c.makeActionList();
        c.persistSubjectList = [{
            taskKey: 71,
            state: null,
            selectPermission: 0,
            isExecuteApplicable: 1
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            selectPermission: 2,
            oldselectPermission: null,
            isExecuteApplicable: 1
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Added');
        expect(c.permissonChangedList[0].objectTable).toEqual('DATATOPIC');
    });
    it('should call makeActionList Delete', () => {
        c.makeActionList();
        c.persistSubjectList = [{
            taskKey: 71,
            state: null,
            selectPermission: 1,
            isExecuteApplicable: 1
        }];
        c.permissonChangedList = [{
            taskKey: 71,
            state: null,
            selectPermission: 0,
            oldselectPermission: null,
            isExecuteApplicable: 1
        }];
        c.makeActionList();
        expect(c.permissonChangedList[0].state).toEqual('Deleted');
        expect(c.permissonChangedList[0].objectTable).toEqual('DATATOPIC');
    });
});