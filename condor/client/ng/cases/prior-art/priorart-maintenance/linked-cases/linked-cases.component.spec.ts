import { fakeAsync, tick } from '@angular/core/testing';
import { PriorArtServiceMock } from 'cases/prior-art/priorart.service.mock';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock, IpxGridOptionsMock, IpxNotificationServiceMock, NotificationServiceMock, StateServiceMock } from 'mocks';
import { of } from 'rxjs';
import { AddLinkedCasesComponent } from './add-linked-cases/add-linked-cases.component';
import { LinkedCasesComponent } from './linked-cases.component';
import { UpdateFirstLinkedComponent } from './update-first-linked-case/update-first-linked.component';

describe('LinkedCasesComponent', () => {
    let component: LinkedCasesComponent;
    let service: PriorArtServiceMock;
    let cdr: ChangeDetectorRefMock;
    let stateService: StateServiceMock;
    let localSettings: LocalSettingsMock;
    let ipxModalService: {
        openModal: jest.Mock
    };
    let notificationService: NotificationServiceMock;
    let ipxNotificationService: IpxNotificationServiceMock;
    beforeEach(() => {
        service = new PriorArtServiceMock();
        cdr = new ChangeDetectorRefMock();
        stateService = new StateServiceMock();
        localSettings = new LocalSettingsMock();
        notificationService = new NotificationServiceMock();
        ipxModalService = {
            openModal: jest.fn()
        };
        ipxModalService.openModal.mockReturnValue({ content: { success$: of(true), confirmed$: of(true) } });
        ipxNotificationService = new IpxNotificationServiceMock();
        ipxNotificationService.openConfirmationModal.mockReturnValue({ content: { confirmed$: of(true) } });
        component = new LinkedCasesComponent(service as any,
            cdr as any,
            stateService as any,
            localSettings as any,
            ipxModalService as any,
            notificationService as any,
            ipxNotificationService as any
        );
        component.grid = { getRowSelectionParams: jest.fn().mockReturnValue({ isAllPageSelect: false, rowSelection: [] }), clearSelection: jest.fn(), getSelectedItems: jest.fn() } as any;
        component.hasUpdatePermission = true;
        component.hasDeletePermission = true;
        component.subscribeToUpdates = jest.fn();
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    describe('refreshGrid', () => {
        it('should refresh the grid', () => {
            component.gridOptions = new IpxGridOptionsMock();

            component.refreshGrid();

            expect(component.gridOptions._search).toHaveBeenCalled();
            expect(component.grid.clearSelection).toHaveBeenCalled();
        });
    });

    describe('ngOnInit', () => {
        it('should set the grid options and bulk action options', () => {
            component.gridOptions = null;
            component.bulkActions = null;

            component.ngOnInit();

            expect(component.gridOptions).not.toBeNull();
            expect(component.bulkActions).toHaveLength(3);
        });
        it('should not have bulk action options for delete if not permitted', () => {
            component.gridOptions = null;
            component.bulkActions = null;
            component.hasDeletePermission = false;

            component.ngOnInit();

            expect(component.bulkActions).toHaveLength(2);
        });
        it('should not have bulk action options for update if not permitted', () => {
            component.gridOptions = null;
            component.bulkActions = null;
            component.hasUpdatePermission = false;

            component.ngOnInit();

            expect(component.bulkActions).toHaveLength(1);
        });
        it('should not have bulk action options if not permitted', () => {
            component.gridOptions = null;
            component.bulkActions = null;
            component.hasUpdatePermission = false;
            component.hasDeletePermission = false;

            component.ngOnInit();

            expect(component.bulkActions).toBeNull();
        });
    });

    describe('linkCases', () => {
        it('should open the modal and refresh on success', fakeAsync(() => {
            component.sourceData = { data: { sourceId: -1234, id: 555 } };
            component.linkCases();

            expect(ipxModalService.openModal.mock.calls[0][0]).toBe(AddLinkedCasesComponent);
            expect(ipxModalService.openModal.mock.calls[0][1]).toEqual(expect.objectContaining({ initialState: { sourceData: component.sourceData, invokedFromCases: true } }));
            tick();
            expect(service.hasUpdatedAssociations$.next).toHaveBeenCalledWith(true);
        }));
    });

    describe('changeFirstLinked', () => {
        it('should open the modal', () => {
            component.sourceData = { sourceId: 123 };
            component.changeFirstLinked();

            expect(ipxModalService.openModal).toHaveBeenCalledWith(UpdateFirstLinkedComponent, expect.anything());
        });
    });

    describe('changing status', () => {
        it('should open the modal', fakeAsync(() => {
            spyOn(component, 'refreshGrid');
            component.sourceData = { sourceId: 5552368 };
            component.grid.getRowSelectionParams = jest.fn().mockReturnValue({ rowSelection: [5, 55, 236, 8], isAllPageSelect: false });
            component.changeStatus();
            expect(ipxModalService.openModal.mock.calls[0][1].initialState).toEqual(expect.objectContaining({ caseKeys: [5, 55, 236, 8], sourceDocumentId: 5552368 }));
            tick();
            expect(notificationService.success).toHaveBeenCalled();
            expect(component.refreshGrid).toHaveBeenCalled();
        }));
        it('should cater for Select All', fakeAsync(() => {
            spyOn(component, 'refreshGrid');
            component.sourceData = { sourceId: 5552368 };
            component.grid.getRowSelectionParams = jest.fn().mockReturnValue({ rowSelection: [5, 55, 236, 8], isAllPageSelect: true, allDeSelectedItems: [{caseKey: 111}, {caseKey: -222}] });
            component.changeStatus();
            expect(ipxModalService.openModal.mock.calls[0][1].initialState).toEqual(expect.objectContaining({ caseKeys: [], sourceDocumentId: 5552368, isSelectAll: true, exceptCaseKeys: [111, -222] }));
            tick();
            expect(notificationService.success).toHaveBeenCalled();
            expect(component.refreshGrid).toHaveBeenCalled();
        }));
    });

    describe('removing linked cases', () => {
        it('should display a confirmation modal', fakeAsync(() => {
            component.sourceData = { sourceId: Math.random() };
            component.removeLinkedCases();
            tick();
            expect(ipxNotificationService.openConfirmationModal).toHaveBeenCalled();
        }));
        it('should pass list of caseKeys if multiple selected', fakeAsync(() => {
            component.sourceData = { sourceId: 8765 };
            component.grid.getRowSelectionParams = jest.fn().mockReturnValue({ rowSelection: [5, 55, 236, 8], isAllPageSelect: false });
            component.removeLinkedCases();
            expect(ipxNotificationService.openConfirmationModal).toHaveBeenCalled();
            tick();
            expect(service.removeLinkedCases$.mock.calls[0][0]).toEqual(expect.objectContaining({ sourceDocumentId: 8765, caseKeys: [5, 55, 236, 8] }));
        }));
        it('should refresh the grid on successful save', fakeAsync(() => {
            service.removeLinkedCases$ = jest.fn().mockReturnValue(of({ isSuccessful: true }));
            component.sourceData = { sourceId: 8765 };
            component.grid.getRowSelectionParams = jest.fn().mockReturnValue({ rowSelection: [5, 55, 236, 8], isAllPageSelect: false });
            component.removeLinkedCases();
            expect(ipxNotificationService.openConfirmationModal).toHaveBeenCalled();
            tick();
            expect(service.removeLinkedCases$.mock.calls[0][0]).toEqual(expect.objectContaining({ sourceDocumentId: 8765, caseKeys: [5, 55, 236, 8] }));
            tick();
            expect(notificationService.success).toHaveBeenCalled();
            expect(service.hasUpdatedAssociations$.next).toHaveBeenCalledWith(true);
        }));
        it('should cater for select all', fakeAsync(() => {
            service.removeLinkedCases$ = jest.fn().mockReturnValue(of({ isSuccessful: true }));
            component.sourceData = { sourceId: 8766 };
            component.grid.getRowSelectionParams = jest.fn().mockReturnValue({ rowSelection: [], isAllPageSelect: true, allDeSelectedItems: [{caseKey: 333}, {caseKey: 444}] });
            component.removeLinkedCases();
            expect(ipxNotificationService.openConfirmationModal).toHaveBeenCalled();
            tick();
            expect(service.removeLinkedCases$.mock.calls[0][0]).toEqual(expect.objectContaining({ sourceDocumentId: 8766, caseKeys: [], isSelectAll: true, exceptCaseKeys: [333, 444] }));
            tick();
            expect(notificationService.success).toHaveBeenCalled();
            expect(service.hasUpdatedAssociations$.next).toHaveBeenCalledWith(true);
        }));
    });
});
