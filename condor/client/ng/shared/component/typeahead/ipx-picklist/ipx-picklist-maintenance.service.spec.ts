import { GridNavigationServiceMock, HttpClientMock, NotificationServiceMock } from 'mocks';
import { Observable, of } from 'rxjs';
import { IpxPicklistMaintenanceService } from './ipx-picklist-maintenance.service';

describe('Picklist Maintenance Service test', () => {
    let service: IpxPicklistMaintenanceService;
    let httpClientSpy: any;
    let notificationServiceMock: any;
    let gridNavigationService: GridNavigationServiceMock;
    beforeEach(() => {
        httpClientSpy = new HttpClientMock();
        notificationServiceMock = new NotificationServiceMock();
        gridNavigationService = new GridNavigationServiceMock();
        service = new IpxPicklistMaintenanceService(httpClientSpy, notificationServiceMock, null, gridNavigationService as any);
    });
    beforeEach(() => {
        notificationServiceMock.openDeleteConfirmModal.mockReturnValue({ content: { confirmed$: of({ value: true }), cancelled$: null } });
        httpClientSpy.put.mockReturnValue(of({ result: 'success', errors: null }));
        httpClientSpy.post.mockReturnValue(of({ result: 'success', errors: null }));
    });

    it('should setup modalStates', () => {
        expect(service.modalStates$).toBeDefined();
        expect(service.modalStates$.getValue()).toEqual({
            isMaintenanceMode: false,
            canAdd: false,
            canSave: false
        });
    });
    it('should setup maintenanceMetaData', () => {
        expect(service.maintenanceMetaData$).toBeDefined();
        expect(service.maintenanceMetaData$.getValue()).toEqual({
            maintainability: {
                canAdd: false,
                canDelete: false,
                canEdit: false
            },
            maintainabilityActions: {
                allowAdd: false,
                allowDelete: false,
                allowDuplicate: false,
                allowEdit: false,
                allowView: false,
                action: ''
            }
        });
    });
    it('should addOrUpdate$ behave correctly', () => {
        service.addOrUpdate$('uri', { key: 'key', value: 'value' });
        expect(httpClientSpy.put).toHaveBeenCalledWith('uri/key', { key: 'key', value: 'value' });

        service.addOrUpdate$('uri', { key: null, value: 'value' });
        expect(httpClientSpy.post).toHaveBeenCalledWith('uri', { value: 'value' });

    });

    it('should initNavigationOptions', () => {
        const apiUrl = 'api/picklists/fileParts';
        const keyField = 'key';
        service.initNavigationOptions(apiUrl, keyField);
        expect(service.navigationOptions).toEqual({
            apiUrl: 'api/picklists/fileParts',
            keyField: 'key'
        });
        expect(gridNavigationService.init).toHaveBeenCalled();
    });

    it('should generic getItem with fetchItemUri', () => {
        const typeaheadOptions = { apiUrl: 'api/picklists/fileParts', fetchItemUri: 'case/{0}', fetchItemParam: 'caseId' };
        const model = {
            key: 1,
            value: 'Part 1',
            caseId: -487,
            rowKey: '1',
            selected: false
        };
        jest.spyOn(service, 'getItem$').mockReturnValue(of({
            key: 1,
            value: 'Part 1',
            caseId: -487
        }));
        service.getItem$(typeaheadOptions, model).subscribe(result => {
            expect(result).toBeTruthy();
            expect(result).toEqual({
                value: 'Part 1',
                caseId: -487
            });
        });
    });

    it('should generic getItem with without fetchItemUri', () => {
        const typeaheadOptions = { apiUrl: 'api/picklists/dataItems', fetchItemParam: 'caseId' };
        const model = {
            key: 1032,
            value: 'Part 1',
            caseId: -487,
            rowKey: '1',
            selected: false
        };
        jest.spyOn(service, 'getItem$').mockReturnValue(of({
            key: 1032,
            code: 'Adhocs mismatch names on Case',
            value: 'Adhoc alerts exist for staff members that are not associated with the Case',
            entryPointUsage: {
              name: null,
              description: null
            }
          }));
        service.getItem$(typeaheadOptions, model).subscribe(result => {
            expect(result).toBeTruthy();
            expect(result).toEqual({
                key: 1032,
                code: 'Adhocs mismatch names on Case',
                value: 'Adhoc alerts exist for staff members that are not associated with the Case',
                entryPointUsage: {
                  name: null,
                  description: null
                }
              });
        });
    });

    it('should delete ', () => {
        service.delete$('uri', 'key', { params: {} });
        expect(httpClientSpy.delete).toHaveBeenCalledWith('uri/key');
    });

    it('should getItems', () => {
        httpClientSpy.get = (a, b) =>
            of({
                maintainability: {
                    canAdd: true,
                    canDelete: true,
                    canEdit: true
                },
                maintainabilityActions: {
                    allowAdd: true,
                    allowDelete: true,
                    allowDuplicate: true,
                    allowEdit: true,
                    allowView: true
                }
            });

        service.getItems$('uri', { params: {} }).subscribe(() => {
            expect(httpClientSpy.get).toHaveBeenCalledWith('uri', { params: {} });
            expect(service.modalStates$.getValue()).toEqual({
                isMaintenanceMode: false,
                canAdd: true,
                canSave: false
            });
            expect(service.maintenanceMetaData$.getValue()).toEqual(
                {
                    maintainability: {
                        canAdd: true,
                        canDelete: true,
                        canEdit: true
                    },
                    maintainabilityActions: {
                        allowAdd: true,
                        allowDelete: true,
                        allowDuplicate: true,
                        allowEdit: true,
                        allowView: true
                    }
                });
        });
    });
});