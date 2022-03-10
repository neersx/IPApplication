import { BillingStepsPersistanceService } from 'accounting/billing/billing-steps-persistance.service';
import { BillingServiceMock } from 'accounting/billing/billing.mocks';
import { ChangeDetectorRefMock } from 'mocks';
import { of } from 'rxjs';
import { BillingReferencesComponent } from './billing-references.component';

describe('BillingReferencesComponent', () => {
  let component: BillingReferencesComponent;
  let cdr: ChangeDetectorRefMock;
  let service: {
    getDefaultReferences: any;
  };
  let billingStepsService: BillingStepsPersistanceService;
  let billingService: BillingServiceMock;

  beforeEach(() => {
    service = {
      getDefaultReferences: jest.fn().mockReturnValue(of({ ItemTransactionId: 123, ItemEntityId: 345, ReferenceText: 'This is reference text', Regarding: 'Regarding text value' }))
    };
    billingStepsService = new BillingStepsPersistanceService();
    billingService = new BillingServiceMock();
    cdr = new ChangeDetectorRefMock();
    component = new BillingReferencesComponent(cdr as any, billingService as any, service as any, billingStepsService as any);
    component.defaultBillReference = { ReferenceText: '' };
    component.caseStepData = {
      currentAction: { key: 1, code: 'abc' },
      entity: 123455,
      raisedBy: { key: 1 },
      caseData: [{ CaseId: 123, Title: 'Text Case Title' }],
      useRenewalDebtor: true,
      debtorData: [{ NameId: 223, DebtorCheckbox: true }]
    };
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('initialize component', () => {
    const stepResponse = {
      stepData: {
        currentAction: { key: 1, code: 'abc' },
        entity: 123455,
        raisedBy: { key: 1 },
        caseData: [{ CaseId: 123, Title: 'Text Case Title' }],
        useRenewalDebtor: true,
        debtorData: [{ NameId: 223, DebtorCheckbox: true }]
      }
    };
    billingStepsService.getStepData = jest.fn().mockReturnValue(stepResponse);
    component.ngOnInit();
    expect(component.caseStepData).not.toBeNull();
  });

  it('should call narrativesFor', () => {
    const query = { debtor: 123 };
    component.narrativesFor(query);
    expect(component).toBeTruthy();
  });

  it('should call prapareReferenceRequest', () => {
    component.prepareReferenceRequest();
    expect(component.selectedDebtor).toEqual({ NameId: 223, DebtorCheckbox: true });
  });

  it('should copy correct copyCaseTitle', () => {
    component.caseStepData = {
      currentAction: { key: 1, code: 'abc' },
      entity: 123455,
      raisedBy: { key: 1 },
      caseData: [{ CaseId: 123, Title: 'Text Case Title' }],
      useRenewalDebtor: true,
      debtorData: [{ NameId: 223, DebtorCheckbox: true }]
    };
    const title = component.caseStepData.caseData.map(x => x.Title).join(', ');
    component.copyCaseTitle();
    expect(component.defaultBillReference.ReferenceText).toEqual(title);
  });

  it('should call onNarrativeChange', () => {
    const value = { text: 'text value to replace', value: 'text value' };
    component.onNarrativeChange(value);
    expect(component.defaultBillReference.Regarding).toEqual(value.text);
  });

});
