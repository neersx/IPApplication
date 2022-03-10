import { ChangeDetectorRefMock, DateHelperMock, IpxNotificationServiceMock, TranslateServiceMock } from 'mocks';
import { BillingStepsPersistanceService } from './billing-steps-persistance.service';
import { BillingComponent } from './billing.component';
import { BillingServiceMock, BillingStateServiceMock } from './billing.mocks';

describe('BillingComponent', () => {
    let component: BillingComponent;
    let cdr: ChangeDetectorRefMock;
    let service: BillingServiceMock;
    let stateService: BillingStateServiceMock;
    let billingStateService: BillingStateServiceMock;
    let dateHelper: DateHelperMock;
    let stepsService: BillingStepsPersistanceService;
    let translate: TranslateServiceMock;
    let ipxNotificationService: IpxNotificationServiceMock;

    beforeEach(() => {
        service = new BillingServiceMock();
        cdr = new ChangeDetectorRefMock();
        stateService = new BillingStateServiceMock();
        billingStateService = new BillingStateServiceMock();
        dateHelper = new DateHelperMock();
        stepsService = new BillingStepsPersistanceService();
        translate = new TranslateServiceMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        component = new BillingComponent(stateService as any, service as any, cdr as any, stepsService as any, dateHelper as any, translate as any, ipxNotificationService as any);
        component.viewData = { Site: { ReasonList: {} } };
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    describe('initialize component', () => {
        it('should set billing type from query param', () => {
            component.ngOnInit();
            expect(component.billingType).toBe(stateService.params.type);
            expect(component.openItemNo).toBe(stateService.params.openItemNo);
            expect(component.entityId).toBe(stateService.params.entityId);
        });

        it('should call openItem from service', (done) => {
            service.openItemData$.next = jest.fn();
            component.ngOnInit();
            expect(service.getOpenItem$).toHaveBeenCalled();
            service.getOpenItem$(component.billingType, component.openItemNo, component.entityId).subscribe((openItemData: any) => {
                expect(component.openItemData).toBe(component.openItemData);
                expect(service.openItemData$.next).toHaveBeenCalledWith(component.openItemData);
                expect(cdr.markForCheck).toHaveBeenCalled();
                done();
            });
        });

        it('verify ngOnInit for creating single bill', () => {
            service.openItemData$.next = jest.fn();
            component.viewData.singleBillData = {
                billPreparationData: { entityId: 1, includeNonRenewal: true, includeRenewal: true, raisedBy: { key: 110 }, useRenewalDebtor: false },
                itemType: 1,
                selectedItems: [{ key: 1, caseKey: 221 }],
                debtorKey: 3,
                selectedCases: []
            };
            component.ngOnInit();
            expect(service.openItemData$.next).toHaveBeenCalled();
            expect(component.singleBillViewData).toBe(component.viewData.singleBillData);
        });

    });
});