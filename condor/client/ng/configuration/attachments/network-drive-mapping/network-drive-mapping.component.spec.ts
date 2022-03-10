import { ChangeDetectorRefMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { BehaviorSubject } from 'rxjs';
import { AttachmentConfigurationServiceMock } from '../attachments-configuration.service.mock';
import { NetworkDriveMappingMaintenanceComponent } from './network-drive-mapping-maintenance.component';
import { NetworkDriveMappingComponent } from './network-drive-mapping.component';

describe('NetworkDriveMappingComponent', () => {
    let component: (storageLocations?: Array<any>) => NetworkDriveMappingComponent;
    let modalService: ModalServiceMock;
    let cdRef: ChangeDetectorRefMock;
    let service: AttachmentConfigurationServiceMock;
    beforeEach(() => {
        modalService = new ModalServiceMock();
        cdRef = new ChangeDetectorRefMock();
        service = new AttachmentConfigurationServiceMock();
        component = (storageLocations?: Array<any>) => {
            const c = new NetworkDriveMappingComponent(modalService as any, cdRef as any, service as any);
            c.topic = {
                hasErrors$: new BehaviorSubject<boolean>(false),
                setErrors: jest.fn(),
                getErrors: jest.fn(),
                params: {
                    viewData: storageLocations || [
                        {
                            networkDriveMappingId: 10,
                            driveLetter: 'Z',
                            uncPath: 'c:\\server1'
                        }
                    ]
                }
            } as any;
            c.ngOnInit();

            return c;
        };
    });

    it('should create', () => {
        expect(component()).toBeTruthy();
    });

    it('should set network drive rows', () => {
        const c = component();
        expect(c.topic.getDataChanges).toBeDefined();
        expect(c.networkDriveMapping.length).toBe(1);
        expect(c.gridOptions).toBeDefined();
        expect(c.gridOptions.rowMaintenance).toEqual({ canEdit: true, canDelete: true, rowEditKeyField: 'networkDriveMappingId' });
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
                networkDriveMappingId: 0,
                driveLetter: 'Z',
                uncPath: 'c:\\server1',
                rowkey: 1,
                status: null
            },
            rowIndex: 1
        };

        c.onRowAddedEdited(data, true);

        expect(c.gridOptions.rowMaintenance.rowEditKeyField).toEqual('networkDriveMappingId');
        expect(modalService.openModal).toHaveBeenCalledWith(NetworkDriveMappingMaintenanceComponent,
            {
                animated: false,
                backdrop: 'static',
                class: 'modal-lg',
                initialState: {
                    dataItem: data.dataItem,
                    isAdding: true,
                    grid: c.grid,
                    rowIndex: data.rowIndex
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
                        networkDriveMappingId: 0,
                        driveLetter: 'Z',
                        uncPath: 'c:\\server1'
                    }, {
                        networkDriveMappingId: 1,
                        driveLetter: 'X',
                        uncPath: 'c:\\server2'
                    }
                ]
        } as any;
        c.updateChangeStatus();
        c.topic.hasErrors$.subscribe((err) => { expect(err).toBeFalsy(); });
        expect(c.grid.checkChanges).toHaveBeenCalled();
        expect(c.gridOptions.rowMaintenance).toEqual({ canEdit: true, canDelete: true, rowEditKeyField: 'networkDriveMappingId' });
    });
});
