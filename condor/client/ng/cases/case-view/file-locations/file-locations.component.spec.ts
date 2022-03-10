import { FormControl, FormGroup } from '@angular/forms';
import { RootScopeServiceMock } from 'ajs-upgraded-providers/mocks/rootscope.service.mock';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import { FileLocationsComponent, WhenMovedEnum } from './file-locations.component';

describe('FileHistoryComponent', () => {
    let component: FileLocationsComponent;
    const modalServiceMock = new ModalServiceMock();
    const localSettings = new LocalSettingsMock();
    const rootScopeService = new RootScopeServiceMock();
    let service: {
        getFileLocations(caseKey: number, queryParams: any, showHistory?: boolean): any;
        formatFileLocation(value: any): any;
        getCaseReference(caseKey: number): any;
        toLocalDate(date: any): any;
    };
    const topic: Topic = {
        key: '',
        title: '',
        params: {
            viewData: {
                irn: 123
            }
        }
    };
    beforeEach(() => {
        service = {
            getFileLocations: jest.fn(),
            formatFileLocation: jest.fn().mockReturnValue({
                fileLocation: 'abc',
                fiePart: 'Part 1'
            }),
            getCaseReference: jest.fn().mockReturnValue('123'),
            toLocalDate: jest.fn().mockReturnValue(new Date())
        };
        component = new FileLocationsComponent(localSettings as any, rootScopeService as any, modalServiceMock as any, service as any);
        component.topic = topic;
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
        jest.spyOn(component, 'getCaseReference').mockReturnValue();
        component.ngOnInit();
        expect(component.isHosted).toBeTruthy();
        expect(component.getCaseReference).toBeCalled();
        expect(component.topic.hasChanges).toBeFalsy();
    });

    it('open file location history modal', () => {
        jest.spyOn(modalServiceMock, 'openModal');
        const params = {
            animated: false,
            backdrop: 'static',
            class: 'modal-xl',
            initialState: {
                topic,
                isHosted: component.isHosted,
                permissions: component.permissions,
                fileHistoryFromMaintenance: false
            }
        };
        component.openFileLocationHistory();
        expect(modalServiceMock.openModal).toHaveBeenCalledWith(expect.anything(), params);
    });

    it('getchanges called before save', () => {
        component.grid = {
            rowEditFormGroups: {
                ['1']: new FormGroup({
                    fileLocation: new FormControl('abc'),
                    filePart: new FormControl('Part 1'),
                    status: new FormControl('A')
                }),
                ['2']: new FormGroup({
                    fileLocation: new FormControl('xyz'),
                    filePart: new FormControl('Part 2'),
                    status: new FormControl('E')
                }),
                ['3']: new FormGroup({
                    fileLocation: new FormControl('123'),
                    filePart: new FormControl('Part 3'),
                    status: new FormControl('D')
                })
            }
        } as any;

        jest.spyOn(service, 'formatFileLocation');
        const data = component.getChanges();
        expect(data).toBeDefined();
        expect(service.formatFileLocation).toBeCalledWith(component.grid.rowEditFormGroups[3].value);
        expect(data.fileLocations.rows.length).toBeGreaterThan(0);
    });
});