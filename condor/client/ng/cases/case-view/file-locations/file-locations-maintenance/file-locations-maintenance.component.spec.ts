import { FormBuilder } from '@angular/forms';
import { BsModalRefMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { Observable } from 'rxjs';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import { WhenMovedEnum } from '../file-locations.component';
import { FileLocationsMaintenanceComponent } from './file-locations-maintenance.component';

describe('File Locations Maintenance Component', () => {
    let component: FileLocationsMaintenanceComponent;
    const notificationService = new NotificationServiceMock();
    const bsModalRef = new BsModalRefMock();
    const translate = new TranslateServiceMock();
    const modalService = new ModalServiceMock();
    const formBuilder = new FormBuilder();
    let service: {
        getFileLocations(caseKey: number, queryParams: any, showHistory?: boolean): any;
        isAddAnotherChecked: any;
        getValidationErrors(caseKey, formGroup: any, changedRows: any): any;
        formatFileLocation: any;
    };
    const topic: Topic = {
        key: '',
        title: '',
        params: {
            viewData: {
                irn: 'abc/123',
                caseKey: 123
            }
        }
    };
    beforeEach(() => {

        service = {
            getFileLocations: jest.fn(),
            isAddAnotherChecked: { getValue: jest.fn().mockReturnValue(true) },
            getValidationErrors: jest.fn().mockReturnValue(new Observable()),
            formatFileLocation: jest.fn()
        };
        component = new FileLocationsMaintenanceComponent(service as any, notificationService as any, bsModalRef as any, modalService as any, translate as any, formBuilder);
        component.topic = topic;
        component.hasError = false;
        component.grid = new IpxKendoGridComponentMock();

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
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('initialize component', () => {
        component.ngOnInit();
        expect(service.isAddAnotherChecked.getValue).toBeTruthy();
    });

    it('check if time picker is disabled or not', () => {
        let isDisabled = component.isMovedTimeDisabled();
        expect(isDisabled).toBeFalsy();

        component.permissions.WHEN_MOVED_SETTINGS = WhenMovedEnum.AllowDateButTimeDisabledWithCurrentTime;
        isDisabled = component.isMovedTimeDisabled();
        expect(isDisabled).toBeTruthy();
    });

    it('check if date picker is disabled or not', () => {
        const isDisabled = component.isMovedDateDisabled();
        expect(isDisabled).toBeFalsy();
    });

    it('open file location history modal', () => {
        jest.spyOn(modalService, 'openModal');
        const params = {
            animated: false,
            backdrop: 'static',
            class: 'modal-xl',
            initialState: {
                topic,
                isHosted: false,
                permissions: component.permissions,
                fileHistoryFromMaintenance: true
            }
        };
        component.formGroup = {
            value: {
                id: 1,
                fileLocation: 123,
                filePart: 1,
                status: 'A'
            }
        };
        component.openFileLocationHistory();
        expect(modalService.openModal).toHaveBeenCalledWith(expect.anything(), params);
    });

    it('show validation form data errors', () => {

        component.formGroup = {
            value: {
                id: 1,
                fileLocation: 123,
                filePart: 1,
                status: 'A'
            }
        };
        component.grid.wrapper.data = {
            data: [{
                id: 1,
                fileLocation: 123,
                filePart: 1,
                status: 'A'
            },
            {
                id: 2,
                fileLocation: 345,
                filePart: 2,
                status: 'E'
            }]
        };
        component.grid.rowEditFormGroups = [{
            id: 2,
            fileLocation: 345,
            filePart: 2
        }];
        component.validate();
        service.getValidationErrors(component.topic.params.viewData.caseKey, component.grid.rowEditFormGroups, component.grid.wrapper.data).subscribe(err => {
            expect(err).toBeDefined();
            expect(err.length).toBeGreaterThan(0);
            expect(err.field).toBe('fileLocation');
            expect(component.hasError).toBeTruthy();
            expect(notificationService.openAlertModal).toBeCalled();
        });
        expect(service.isAddAnotherChecked.getValue).toBeTruthy();
    });
});