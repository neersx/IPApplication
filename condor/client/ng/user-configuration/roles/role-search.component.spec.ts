import { ChangeDetectorRefMock, IpxGridOptionsMock, KeyBoardShortCutService, NotificationServiceMock, RoleSearchMock, StateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { RoleSearchComponent } from './role-search.component';

describe('RoleSearchComponent', () => {
    let component: RoleSearchComponent;
    const service = new RoleSearchMock();
    const cdr = new ChangeDetectorRefMock();
    const gridoptionsMock = new IpxGridOptionsMock();
    const stateMock = new StateServiceMock();
    const keyBoardShortMock = new KeyBoardShortCutService();
    const notificationService = new NotificationServiceMock();
    const modalService = new ModalServiceMock();
    const translateService = { instant: jest.fn() };
    beforeEach(() => {
        component = new RoleSearchComponent(service as any, cdr as any, stateMock as any, keyBoardShortMock as any,
            notificationService as any,
            translateService as any, modalService as any);
        component.gridOptions = new IpxGridOptionsMock() as any;
        component._resultsGrid = new IpxKendoGridComponentMock() as any;
        component.roleSearchGrid = new IpxKendoGridComponentMock() as any;
    });
    it('should initialize RoleSearchComponent', () => {
        expect(component).toBeTruthy();
    });
    it('should call Oninit', () => {
        component.ngOnInit();
        expect(component.formData).toBeDefined();
        expect(component.permission.length).toEqual(3);
    });
    it('should call toggleInternal', () => {
        component.initFormData();
        component.formData.isExternal = false;
        component.formData.isInternal = false;
        component.toggleInternal(null, 0);
        expect(component.formData.isExternal).toEqual(true);
        component.toggleInternal(null, 1);
        expect(component.formData.isInternal).toEqual(true);
    });
    it('should call onChangeTask', () => {
        component.initFormData();
        component.formData.task.execute = true;
        component.onChangeTask();
        expect(component.formData.task.execute).toEqual(false);
        component.formData.task.permissions = '1';
        component.formData.task.Picklist = {
            executePermission: true, updatePermission: true,
            insertPermission: true, deletePermission: true
        };
        component.onChangeTask();
        expect(component.formData.task.execute).toEqual(true);
        expect(component.formData.task.update).toEqual(true);
        expect(component.formData.task.insert).toEqual(true);
        expect(component.formData.task.delete).toEqual(true);
    });
    it('should call onChangeWebpart', () => {
        component.initFormData();
        component.onChangeWebpart();
        expect(component.formData.webPart.access).toEqual(false);
        component.formData.webPart.permissions = '1';
        component.formData.webPart.Picklist = { name: 'data' };
        component.onChangeWebpart();
        expect(component.formData.webPart.access).toEqual(true);
    });
    it('should call onChangeSubject', () => {
        component.initFormData();
        component.onChangeSubject();
        expect(component.formData.subject.access).toEqual(false);
        component.formData.subject.permissions = '1';
        component.formData.subject.Picklist = { name: 'data' };
        component.onChangeSubject();
        expect(component.formData.subject.access).toEqual(true);
    });

    it('should call search', () => {
        component.initFormData();
        component.formData.roleName = 'Role One';
        component.formData.description = 'Role One description';
        component.gridOptions = gridoptionsMock;
        spyOn(gridoptionsMock, '_search').and.returnValue([]);
        component.search();
        expect(component.gridOptions._search).toBeCalled();
    });

    it('should call initShortcuts', () => {
        component.initShortcuts();
        expect(keyBoardShortMock.add).toHaveBeenCalled();
    });
    it('should call deleteSelectedColumns method', () => {
        component.deleteSelectedRoles();
        expect(service.deleteroles).toBeCalled();
    });
    it('should call openModal method', () => {
        const state = 'adding';
        component.openModal(null, state);
        expect(modalService.openModal).toBeCalled();
    });

    it('should call dataItemByRoleId method', () => {
        const roleId = 1;
        component._resultsGrid = { wrapper: { data: [{ roleId: 1 }, { roleId: 2 }] } };
        const result = component.dataItemByRoleId(roleId);
        expect(result).toEqual({ roleId: 1 });
    });

});