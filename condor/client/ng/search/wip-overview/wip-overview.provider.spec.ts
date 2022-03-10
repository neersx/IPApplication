import { IpxNotificationServiceMock, StateServiceMock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { Observable } from 'rxjs';
import { WipOverviewProvider } from './wip-overview.provider';

describe('WipOverviewProvider', () => {

    let service: WipOverviewProvider;
    const wipOverviewService = { validateSingleBillCreation: jest.fn().mockReturnValue(new Observable()) };
    let modalService: ModalServiceMock;
    let stateService: StateServiceMock;
    let notificationService: IpxNotificationServiceMock;
    let translate: TranslateServiceMock;

    beforeEach(() => {
        modalService = new ModalServiceMock();
        stateService = new StateServiceMock();
        notificationService = new IpxNotificationServiceMock();
        translate = new TranslateServiceMock();
        service = new WipOverviewProvider(wipOverviewService as any, modalService as any, stateService as any, notificationService as any, translate as any);
    });

    it('should create the service', () => {
        expect(service).toBeTruthy();
    });

    it('verify createSingleBill', () => {
        service.createSingleBill([{ key: 12 }], [{ entityKey: 29, entityName: 'test 1' }]);
        expect(wipOverviewService.validateSingleBillCreation).toHaveBeenCalled();
    });

});
