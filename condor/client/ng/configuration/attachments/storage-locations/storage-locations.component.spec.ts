import { FormBuilder } from '@angular/forms';
import { ChangeDetectorRefMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { BehaviorSubject } from 'rxjs';
import { AttachmentConfigurationServiceMock } from '../attachments-configuration.service.mock';
import { AttachmentsStorageLocationsMaintenanceComponent } from './storage-locations-maintenance.component';
import { AttachmentsStorageLocationsComponent } from './storage-locations.component';

describe('AttachmentsStorageLocationsComponent', () => {
    let component: (storageLocations?: Array<any>) => AttachmentsStorageLocationsComponent;
    let modalService: ModalServiceMock;
    let cdRef: ChangeDetectorRefMock;
    let service: AttachmentConfigurationServiceMock;
    beforeEach(() => {
        modalService = new ModalServiceMock();
        cdRef = new ChangeDetectorRefMock();
        service = new AttachmentConfigurationServiceMock();
        component = (storageLocations?: Array<any>) => {
            const c = new AttachmentsStorageLocationsComponent(modalService as any, cdRef as any, service as any);
            c.topic = {
                key: 'storageLocations',
                title: 'attachmentsIntegration.storageLocations.title',
                hasErrors$: new BehaviorSubject<boolean>(false),
                setErrors: jest.fn(),
                getErrors: jest.fn(),
                params: {
                    viewData: storageLocations || [
                        {
                            storageLocationId: 10,
                            name: 'folder1',
                            path: 'c:\\server1'
                        }
                    ]
                }
            };
            c.ngOnInit();

            return c;
        };
    });

    it('should create', () => {
        expect(component()).toBeTruthy();
    });

    it('should set storage locations rows', () => {
        const c = component();
        expect(c.topic.getDataChanges).toBeDefined();
        expect(c.storageLocations.length).toBe(1);
        expect(c.gridOptions).toBeDefined();
        expect(c.gridOptions.rowMaintenance).toEqual({ canEdit: true, canDelete: true, rowEditKeyField: 'storageLocationId' });
    });

    it('should handle row add correctly', () => {
        modalService.openModal.mockReturnValue({
            content: {
                onClose$: new BehaviorSubject(false)
            }
        });
        const c = component();
        c.updateChangeStatus = jest.fn();
        c.gridOptions.formGroup = { dirty: false } as any;
        c.grid = { rowCancelHandler: jest.fn() } as any;
        const data = {
            dataItem: {
                storageLocationId: 0,
                name: 'folder1',
                path: 'c:\\server1',
                status: null
            },
            rowIndex: 1
        };
        c.onRowAddedEdited(data, true);

        expect(c.gridOptions.rowMaintenance.rowEditKeyField).toEqual('storageLocationId');
        expect(modalService.openModal).toHaveBeenCalledWith(AttachmentsStorageLocationsMaintenanceComponent,
            {
                animated: false,
                backdrop: 'static',
                class: 'modal-lg',
                initialState: {
                    dataItem: data.dataItem,
                    isAdding: true,
                    grid: c.grid,
                    rowIndex: data.rowIndex,
                    validateUrl$: c.validateUrl$
                }
            });
    });

    it('should update status correctly ', () => {
        const c = component();
        c.grid = {
            checkChanges: jest.fn(),
            getCurrentData: () =>
                [
                    {
                        storageLocationId: 0,
                        name: 'folder1',
                        path: 'c:\\server1'
                    }, {
                        storageLocationId: 1,
                        name: 'folder2',
                        path: 'c:\\server2'
                    }
                ]
        } as any;
        c.updateChangeStatus();
        c.topic.hasErrors$.subscribe((err) => { expect(err).toBeFalsy(); });
        expect(c.grid.checkChanges).toHaveBeenCalled();
        expect(c.gridOptions.rowMaintenance).toEqual({ canEdit: true, canDelete: true, rowEditKeyField: 'storageLocationId' });
    });
});
