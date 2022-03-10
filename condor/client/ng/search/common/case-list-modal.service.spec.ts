import { BsModalRefMock, NotificationServiceMock, TypeAheadConfigProvider } from 'mocks';
import { Observable } from 'rxjs';
import { CaseListModalService } from './case-list-modal.service';

describe('CaseListModalService', () => {
    let service: CaseListModalService;
    let notificationService;
    let typeaheadConfigProviderMock;
    let picklistModalServiceMock;
    let caselistModalServiceMock;
    beforeEach(() => {
        const modalRef = new BsModalRefMock();
        notificationService = new NotificationServiceMock();
        typeaheadConfigProviderMock = new TypeAheadConfigProvider();
        picklistModalServiceMock = { openModal: jest.fn().mockReturnValue({ content: { selectedRow$: new Observable() } }) };
        caselistModalServiceMock = { updateCasesListItems: jest.fn() };
        service = new CaseListModalService(notificationService, typeaheadConfigProviderMock, picklistModalServiceMock, caselistModalServiceMock);
    });

    it('should exist', () => {
        expect(service).toBeDefined();
    });

    it('should call openCaselistModal', () => {
        const caseKeys = '12,33,44';
        service.openCaselistModal(caseKeys);
        expect(picklistModalServiceMock.openModal).toHaveBeenCalledTimes(1);
    });
});
