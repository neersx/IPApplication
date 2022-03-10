import { FormControl, FormGroup } from '@angular/forms';
import { ChangeDetectorRefMock } from 'mocks';
import { NotificationServiceMock } from 'mocks/notification-service.mock';
import { Observable, of } from 'rxjs';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { TaskPlannerConfigurationComponent } from './task-planner-configuration.component';

describe('TaskPlannerConfigurationComponent', () => {
    let component: TaskPlannerConfigurationComponent;
    const taskplannerConfigServiceMock = {
        save: jest.fn().mockReturnValue(new Observable())
    };
    let cdr: ChangeDetectorRefMock;
    let notificationService: NotificationServiceMock;

    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        notificationService = new NotificationServiceMock();
        component = new TaskPlannerConfigurationComponent(taskplannerConfigServiceMock as any, cdr as any, {} as any, notificationService as any);
        component.grid = new IpxKendoGridComponentMock();
        component.ngOnInit();
    });

    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('validate ngOnInit', () => {
        component.ngOnInit();
        expect(component.gridOptions).toBeDefined();
    });

    it('validate isGridDirty with no formGroups', () => {
        const result = component.isGridDirty();
        expect(result).toBeFalsy();
    });

    it('validate isGridDirty with formGroups', () => {
        component.grid.rowEditFormGroups = {
            ['1001']: new FormGroup({}),
            ['1002']: new FormGroup({})
        };
        const result = component.isGridDirty();
        expect(result).toBeTruthy();
    });

    it('validate isGridValid with invalid data formGroup', () => {
        component.grid.rowEditFormGroups = { ['1001']: new FormGroup({}), ['1002']: new FormGroup({}) };
        const result = component.isGridValid();
        expect(result).toBeFalsy();
    });

    it('validate isGridValid with valid data formGroup', () => {
        component.grid.rowEditFormGroups = {
            ['1001']: new FormGroup({ profile: new FormControl({ value: { key: 11, code: '11', name: 'test 11' } }), tab1: new FormControl({ value: { key: 211, searchName: 'saved search 211' } }), tab2: new FormControl({ value: { key: 212, searchName: 'saved search 212' } }), tab3: new FormControl({ value: { key: 213, searchName: 'saved search 213' } }) }),
            ['1002']: new FormGroup({ profile: new FormControl({ value: { key: 21, code: '21', name: 'test 21' } }), tab1: new FormControl({ value: { key: 221, searchName: 'saved search 221' } }), tab2: new FormControl({ value: { key: 222, searchName: 'saved search 222' } }), tab3: new FormControl({ value: { key: 223, searchName: 'saved search 223' } }) })
        };
        const result = component.isGridValid();
        expect(result).toBeTruthy();
    });

    it('validate discard', () => {
        component.grid.rowEditFormGroups = {
            ['1001']: new FormGroup({ profile: new FormControl({ value: { key: 11, code: '11', name: 'test 11' } }), tab1: new FormControl({ value: { key: 211, searchName: 'saved search 211' } }), tab2: new FormControl({ value: { key: 212, searchName: 'saved search 212' } }), tab3: new FormControl({ value: { key: 213, searchName: 'saved search 213' } }) }),
            ['1002']: new FormGroup({ profile: new FormControl({ value: { key: 21, code: '21', name: 'test 21' } }), tab1: new FormControl({ value: { key: 221, searchName: 'saved search 221' } }), tab2: new FormControl({ value: { key: 222, searchName: 'saved search 222' } }), tab3: new FormControl({ value: { key: 223, searchName: 'saved search 223' } }) })
        };
        component.discard();
        expect(component.grid.rowEditFormGroups).toBeNull();
        expect(cdr.detectChanges).toHaveBeenCalled();
    });

    it('validate getRowIndex', () => {
        component.currentRowIndexs = [];
        component.grid.rowEditFormGroups = { ['1001']: new FormGroup({}), ['1002']: new FormGroup({}) };
        component.getRowIndex(1);
        expect(component.currentRowIndexs[0]).toEqual(1);
    });

    it('validate getEditedRowIndex', () => {
        component.currentRowIndexs = [];
        component.grid.rowEditFormGroups = { ['1001']: new FormGroup({}), ['1002']: new FormGroup({}) };
        component.getEditedRowIndex({ rowIndex: 2 });
        expect(component.currentRowIndexs[0]).toEqual(2);
    });

    it('validate onSave', () => {
        component.grid.rowEditFormGroups = {
            ['1001']: new FormGroup({ profile: new FormControl({ value: { key: 11, code: '11', name: 'test 11' } }), tab1: new FormControl({ value: { key: 211, searchName: 'saved search 211' } }), tab2: new FormControl({ value: { key: 212, searchName: 'saved search 212' } }), tab3: new FormControl({ value: { key: 213, searchName: 'saved search 213' } }) }),
            ['1002']: new FormGroup({ profile: new FormControl({ value: { key: 21, code: '21', name: 'test 21' } }), tab1: new FormControl({ value: { key: 221, searchName: 'saved search 221' } }), tab2: new FormControl({ value: { key: 222, searchName: 'saved search 222' } }), tab3: new FormControl({ value: { key: 223, searchName: 'saved search 223' } }) })
        };
        component.grid.getCurrentData = jest.fn(() => { return [{ id: 1001 }, { id: 1002 }]; });
        component.onSave();
        expect(taskplannerConfigServiceMock.save).toHaveBeenCalled();
    });

});