import { fakeAsync, tick } from '@angular/core/testing';
import { FormBuilder } from '@angular/forms';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { ChangeDetectorRefMock, HttpClientMock, NotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { BehaviorSubject, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { CaseDetailServiceMock } from '../case-detail.service.mock';
import { FileLocationsGridComponent } from './file-locations-grid.component';
import { FileLocationsMaintenanceComponent } from './file-locations-maintenance/file-locations-maintenance.component';
import { WhenMovedEnum } from './file-locations.component';

describe('FileLocationsGridComponent', () => {
    let component: FileLocationsGridComponent;
    let localSettings: LocalSettingsMock;
    let http: HttpClientMock;
    let modalService: ModalServiceMock;
    const changeDet = new ChangeDetectorRefMock();
    let caseDetailService: CaseDetailServiceMock;
    const notificationService = new NotificationServiceMock();
    const shortcutsService = new IpxShortcutsServiceMock();
    const destroy$ = of({}).pipe(delay(1000));
    let service: {
        getFileLocations(caseKey: number, queryParams: any, showHistory?: boolean): any;
        getFileLocationForFilePart(caseKey: number, queryParams: any, fileHistoryFromMaintenance?: boolean): any;
        caseIrn: string;
        raisePendingChanges(): any;
        raiseHasErrors(): any;
        isAddAnotherChecked: any;
    };
    beforeEach(() => {
        http = new HttpClientMock();
        service = {
            getFileLocations: jest.fn(),
            getFileLocationForFilePart: jest.fn(),
            caseIrn: 'abc123',
            raisePendingChanges: jest.fn(),
            raiseHasErrors: jest.fn(),
            isAddAnotherChecked: jest.fn().mockReturnValue(false)
        };
        caseDetailService = new CaseDetailServiceMock();
        modalService = new ModalServiceMock();
        localSettings = new LocalSettingsMock();
        component = new FileLocationsGridComponent(localSettings as any, service as any, modalService as any, changeDet as any, caseDetailService as any, notificationService as any, destroy$ as any, shortcutsService as any);
        component.isHosted = false;
        component.topic = {
            hasErrors$: new BehaviorSubject<Boolean>(false),
            setErrors: jest.fn(),
            getErrors: jest.fn(),
            hasChanges: false,
            key: 'fileLocations',
            title: 'File Location',
            params: {
                viewData: {
                    caseKey: 123
                }
            }
        } as any;

        component.permissions = {
            CAN_MAINTAIN: true,
            CAN_CREATE_CASE: true,
            CAN_UPDATE: true,
            CAN_DELETE: true,
            WHEN_MOVED_SETTINGS: WhenMovedEnum.AllowBothAndDateTime,
            CAN_REQUEST_CASE_FILE: true,
            DEFAULT_USER_ID: 123,
            DISPLAY_NAME: 'Test User'
        };

        component.grid = {
            checkChanges: jest.fn(),
            isValid: jest.fn(),
            isDirty: jest.fn(),
            onAdd: jest.fn(),
            wrapper: {
                data: [
                    {
                        fileLocationId: 123,
                        fileLocation: 'abc',
                        filePartId: 11,
                        filePart: 'Part 1',
                        barcode: 'barcode',
                        whenMovedDate: new Date(),
                        rowkey: 1,
                        status: 'A'
                    }, {
                        fileLocationId: 456,
                        fileLocation: 'xyz',
                        filePartId: 111,
                        filePart: 'Part 2',
                        barcode: 'barcode1',
                        whenMovedDate: new Date(),
                        rowkey: 2,
                        status: 'E'
                    }
                ]
            }
        } as any;
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    describe('ngOnInit', () => {
        it('should initialise the column configs correctly', () => {
            component.topic = {
                hasErrors$: new BehaviorSubject<Boolean>(false),
                setErrors: jest.fn(),
                params: {
                    viewData: {
                        canRequestCaseFile: true
                    }
                }
            } as any;

            caseDetailService.resetChanges$.next(true);
            component.ngOnInit();
            const columnFields = component.gridOptions.columns.map(col => col.field);
            expect(columnFields).toEqual(['filePart', 'fileLocation', 'bayNo', 'issuedBy', 'whenMoved', 'barCode']);
            expect(component.gridOptions.columns[5].hidden).toBeFalsy();
            expect(component.gridOptions.sortable).toBeTruthy();
            expect(component.gridOptions.filterable).toBeTruthy();
        });

        it('should initialize shortcuts', () => {
            component.ngOnInit();
            expect(shortcutsService.observeMultiple$).toHaveBeenCalledWith([RegisterableShortcuts.ADD]);
        });

        it('should call add on event if hosted', fakeAsync(() => {
            component.isHosted = true;
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.ADD;
            component.ngOnInit();
            tick(shortcutsService.interval);

            expect(component.grid.onAdd).toHaveBeenCalled();
        }));

        it('should initialise the column configs correctly with fileHistoryFromMaintenance', () => {
            component.topic = {
                hasErrors$: new BehaviorSubject<Boolean>(false),
                setErrors: jest.fn(),
                params: {
                    viewData: {
                        canRequestCaseFile: true
                    }
                }
            } as any;

            component.fileHistoryFromMaintenance = true;
            caseDetailService.resetChanges$.next(true);
            component.ngOnInit();
            const columnFields = component.gridOptions.columns.map(col => col.field);
            expect(columnFields).toEqual(['filePart', 'fileLocation', 'bayNo', 'issuedBy', 'whenMoved', 'barCode']);
            expect(component.gridOptions.sortable).toBeFalsy();
            expect(component.gridOptions.filterable).toBeFalsy();
        });

        it('should hide barCode column if canRequestCaseFile is set to false', () => {
            component.topic = {
                hasErrors$: new BehaviorSubject<Boolean>(false),
                setErrors: jest.fn(),
                params: {
                    viewData: {
                        canRequestCaseFile: false
                    }
                }
            } as any;

            component.permissions.CAN_REQUEST_CASE_FILE = false;
            component.ngOnInit();
            expect(component.gridOptions.columns[5].hidden).toBeTruthy();
        });

        it('should call the service on $read', () => {
            component.ngOnInit();
            const queryParams = 'test';
            component.gridOptions.read$(queryParams as any);
            expect(service.getFileLocations).toHaveBeenCalledWith(123, queryParams, false);
        });

        it('should call the service getFileLocationForFilePart on $read', () => {
            component.fileHistoryFromMaintenance = true;
            component.ngOnInit();
            const queryParams = 'test';
            component.gridOptions.read$(queryParams as any);
            expect(service.getFileLocationForFilePart).toHaveBeenCalledWith(123, queryParams, undefined);
        });

        it('should handle row add edit correctly', () => {
            modalService.openModal.mockReturnValue({
                content: {
                    onClose$: new BehaviorSubject(true)
                }
            });
            component.updateChangeStatus = jest.fn();
            component.grid = { rowCancelHandler: jest.fn() } as any;

            const data = {
                dataItem: {
                    fileLocationId: 123,
                    fileLocation: 'abc',
                    filePartId: 11,
                    filePart: 'Part 1',
                    barcode: 'barcode',
                    whenMovedDate: new Date(),
                    rowkey: 1,
                    status: null
                },
                rowIndex: 1
            };
            component.onRowAddedOrEdited(data as any);
            expect(modalService.openModal).toHaveBeenCalledWith(FileLocationsMaintenanceComponent,
                {
                    animated: false,
                    backdrop: 'static',
                    class: 'modal-lg',
                    initialState: {
                        dataItem: data.dataItem,
                        isAdding: false,
                        grid: component.grid,
                        topic: component.topic,
                        permissions: component.permissions,
                        rowIndex: data.rowIndex
                    }
                });
        });

        it('should update status correctly ', () => {
            jest.spyOn(service, 'raisePendingChanges');
            jest.spyOn(service, 'raiseHasErrors');
            component.updateChangeStatus();
            expect(component.grid.checkChanges).toHaveBeenCalled();
            expect(component.topic.hasChanges).toBeTruthy();
            expect(service.raisePendingChanges).toHaveBeenCalled();
            expect(service.raiseHasErrors).toHaveBeenCalled();
        });
    });
});