import { IpxNotificationServiceMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { CaselistMaintenanceComponent } from './caselist-maintenance.component';

describe('CaselistMaintenanceComponent', () => {
    let component: CaselistMaintenanceComponent;
    let translateServiceMock: TranslateServiceMock;
    let notificationServiceMock: NotificationServiceMock;
    const caselistMaintenanceServiceMock = {};
    const ipxPickllistMock = {};
    let ipxNotificationMock: IpxNotificationServiceMock;
    let modalServiceMock: ModalServiceMock;

    beforeEach(() => {
        translateServiceMock = new TranslateServiceMock();
        notificationServiceMock = new NotificationServiceMock();
        ipxNotificationMock = new IpxNotificationServiceMock();
        modalServiceMock = new ModalServiceMock();
        component = new CaselistMaintenanceComponent(translateServiceMock as any,
            notificationServiceMock as any,
            caselistMaintenanceServiceMock as any,
            ipxPickllistMock as any,
            ipxNotificationMock as any,
            modalServiceMock as any);
        component.caselistGrid = new IpxKendoGridComponentMock() as any;
        component.viewData = { permissions: { canUpdateCaseList: false, canInsertCaseList: false, canDeleteCaseList: false } };

    });

    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('validate ngOnInit', () => {
        component.ngOnInit();
        expect(component.gridOptions.bulkActions.length).toEqual(1);
        expect(component.gridOptions).toBeDefined();
        expect(component.gridOptions.bulkActions[0].id).toEqual('delete');
    });

    it('validate openCaseListModal', () => {
        const dataItem = {
            caseKeys: [11, 3],
            value: 'test 1',
            description: 'list desc',
            primeCase: 'primecase123',
            newlyAddedCaseKeys: new Array<number>()
        };
        component.openCaseListModal(dataItem);
        expect(modalServiceMock.openModal).toHaveBeenCalled();
    });
});
