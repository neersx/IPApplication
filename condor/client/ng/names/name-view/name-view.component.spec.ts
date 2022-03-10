import { AppContextServiceMock } from 'core/app-context.service.mock';
import { ChangeDetectorRefMock, HttpClientMock, NotificationServiceMock } from 'mocks';
import { RightBarNavServiceMock } from 'rightbarnav/rightbarnavservice.mock';
import { of } from 'rxjs';
import { NameViewComponent } from './name-view.component';
import { NameViewService } from './name-view.service';
import { NameViewServiceMock } from './name-view.service.mock';

describe('NameViewComponent', () => {
    let component: NameViewComponent;
    const barService = new RightBarNavServiceMock();
    let service = new NameViewServiceMock();
    let httpClientSpy;
    const appCont = new AppContextServiceMock();
    const cdRef = new ChangeDetectorRefMock();
    const notificationService = new NotificationServiceMock();
    let confirmNotificationService: {
        openConfirmationModal: jest.Mock
    };
    const data: any = {
        nameId: 12345,
        nameCode: 'abc',
        name: 'test name',
        program: 'test program',
        sections: {
            screenCriteria: -1,
            sections: [{
                id: '1',
                name: 'invalidTopic'
            }, {
                id: '2',
                name: 'supplierDetails',
                formData: {
                    supplierType: '016969',
                    purchaseDescription: 'buy buy buy',
                    reasonCode: 'bad reason'
                }
            },
            {
                id: '3',
                name: 'nameDocumentManagementSystem'
            }]
        },
        supplierTypes: {},
        taxRates: {},
        taxTreatments: {},
        paymentTerms: {}
    };

    beforeEach(() => {
        httpClientSpy = new HttpClientMock();
        service = new NameViewService(httpClientSpy);
        confirmNotificationService = {
            openConfirmationModal: jest.fn()
        };
        component = new NameViewComponent(service as any, barService as any, appCont as any, cdRef as any, notificationService as any, confirmNotificationService as any);
        component.saveNameData = jest.fn();
    });

    it('should create the component', (() => {
        expect(component).toBeTruthy();
    }));

    it('should initialise topics', (() => {
        component.nameViewData = data;
        component.initialiseTopics();
        expect(component.topicOptions).toBeTruthy();
    }));

    it('should show the correct sections', (() => {
        component.nameViewData = data;
        component.initialiseTopics();
        expect(component.topicOptions.topics.length).toBe(2);
        expect(component.topicOptions.topics[0].key).toBe('supplierDetails');
    }));

    it('should initialise dropdowns', (() => {
        component.nameViewData = data;
        component.initialiseTopics();
        expect(component.nameViewData.supplierTypes).toBeDefined();
        expect(component.nameViewData.taxRates).toBeDefined();
        expect(component.nameViewData.taxTreatments).toBeDefined();
        expect(component.nameViewData.paymentTerms).toBeDefined();
    }));

    it('should show the name DMS section', (() => {
        component.nameViewData = data;
        component.initialiseTopics();
        expect(component.topicOptions.topics.length).toBe(2);
        expect(component.topicOptions.topics[1].key).toBe('nameDocumentManagementSystem');
    }));

    it('should initialise the context navigation bar', (() => {
        component.nameViewData = data;
        component.isSaveEnabled = false;
        component.ngOnInit();
        expect(barService.registercontextuals).toHaveBeenCalled();
    }));

    it('should call save of all topics', (() => {
        component.nameViewData = data;
        component.ngOnInit();
        service.maintainName$ = jest.fn().mockReturnValue(of(true));
        component.saveNameDetails();
        expect(component.saveNameData).toHaveBeenCalled();
    }));
});