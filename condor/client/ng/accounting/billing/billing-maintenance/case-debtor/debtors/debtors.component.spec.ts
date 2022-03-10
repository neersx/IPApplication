import { fakeAsync, tick } from '@angular/core/testing';
import { BillingStepsPersistanceService } from 'accounting/billing/billing-steps-persistance.service';
import { BillingServiceMock } from 'accounting/billing/billing.mocks';
import { AppContextServiceMock } from 'core/app-context.service.mock';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock, IpxNotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { of } from 'rxjs';
import { ActivityEnum, BillingActivity } from '../../case-debtor.model';
import { DebtorsComponent } from './debtors.component';

describe('DebtorsComponent', () => {
  let component: DebtorsComponent;
  let cdr: ChangeDetectorRefMock;
  let modalService: ModalServiceMock;
  let ipxNotificationService: IpxNotificationServiceMock;
  let localSettings = new LocalSettingsMock();
  let appContext: AppContextServiceMock;
  let service: {
    getDebtors: any;
    getCaseDebtorDetails: any;
    getOpenItemDebtors: any;
  };
  let billingStepsService: BillingStepsPersistanceService;
  let billingService: BillingServiceMock;
  beforeEach(() => {
    appContext = new AppContextServiceMock();
    localSettings = new LocalSettingsMock();
    ipxNotificationService = new IpxNotificationServiceMock();
    service = {
      getDebtors: jest.fn().mockReturnValue(of({ errors: null, DebtorList: [{ NameId: 123, BillToNameId: 345 }] })),
      getCaseDebtorDetails: jest.fn().mockReturnValue(of({ errors: null, DebtorList: [{ NameId: 123, BillToNameId: 345 }] })),
      getOpenItemDebtors: jest.fn().mockReturnValue(of({ errors: null, DebtorList: [{ NameId: 123, BillToNameId: 345 }] }))
    };
    billingStepsService = new BillingStepsPersistanceService();
    billingService = new BillingServiceMock();
    cdr = new ChangeDetectorRefMock();
    modalService = new ModalServiceMock();
    component = new DebtorsComponent(billingService as any, service as any, cdr as any, localSettings as any, ipxNotificationService as any, appContext as any, billingStepsService as any, modalService as any);
    component.grid = {
      checkChanges: jest.fn(),
      closeEditedRows: jest.fn(),
      isValid: jest.fn(),
      isDirty: jest.fn(),
      search: jest.fn(),
      resetColumns: jest.fn(),
      wrapper: {
        closeRow: jest.fn(),
        data: [
          {
            NameId: 123,
            DebtorCheckbox: false
          }, {
            NameId: 456,
            DebtorCheckbox: false
          },
          {
            NameId: 789,
            DebtorCheckbox: false
          }
        ]
      }
    } as any;
    component.canSkipWarning = { draftBills: true, differentDebtor: false, changedDebtor: false };
    component.mainCaseId = 123;
    component.request = {
      caseId: 123,
      entityId: -234,
      action: 'RN',
      billDate: null,
      raisedByStaffId: 93,
      useRenewalDebtor: false
    };
    component.debtors = {
      DebtorList: [{ CaseId: 123, NameId: 632, BillToNameId: 345 }]
    };
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
  it('should call clear grid if slected debtor is null', (done) => {
    billingService.currentLanguage$.next = jest.fn();
    component.ngAfterViewInit();
    component.selectDebtors$.subscribe((data) => {
      expect(component.mainCaseId).toBe(null);
      expect(component.debtors).toBe(null);
      expect(component.grid.search).toBeCalled();
      expect(billingService.currentLanguage$.next).toBeCalledWith(null);
      done();
    });
  });

  describe('OnCheckChanged', () => {
    const data = {
      dataItem: {
        NameId: 123
      }
    };
    beforeEach(() => {
      billingStepsService.billingSteps[0].stepData.debtorData = [...component.grid.wrapper.data];
    });
    it('should check debtor for selected row', () => {
      component.resetActivity();
      component.request = null;
      jest.spyOn(component, 'getBillSettingDetails');
      component.onCheckChanged$(data.dataItem);
      expect(component.grid.wrapper.data[0].DebtorCheckbox).toBeTruthy();
    });

    it('should uncheck previous selected debtor when new row is checked', () => {
      const item = {
        dataItem: {
          NameId: 789
        }
      };
      component.resetActivity();
      jest.spyOn(component, 'getBillSettingDetails');
      component.grid.wrapper.data[1].DebtorCheckbox = true;
      component.onCheckChanged$(item.dataItem);
      expect(component.grid.wrapper.data[0].DebtorCheckbox).toBeFalsy();
      expect(component.grid.wrapper.data[1].DebtorCheckbox).toBeFalsy();
      expect(component.grid.wrapper.data[2].DebtorCheckbox).toBeTruthy();
    });

    it('should reset the activity to default', () => {
      const item = {
        dataItem: {
          NameId: 789
        }
      };
      component.resetActivity(true);
      expect(component.activity.onLoaded).toBeTruthy();
      expect(component.activity.onActionChanged).toBeFalsy();
      expect(component.activity.onDebtorChanged).toBeFalsy();
    });
  });

  describe('various api calls', () => {
    it('should call casedebtor summary', () => {
      component.activity = new BillingActivity();
      jest.spyOn(component, 'getDebtorsSummary');
      component.getCaseDebtorsSummary();
      expect(component.request).not.toBeNull();
      expect(component.canFetchOpenItem).toBeFalsy();
      expect(component.getDebtorsSummary).toHaveBeenCalled();
    });

    it('should call getDebtorsSummary api', () => {
      component.activity = new BillingActivity();
      component.newCaseId = 11;
      component.getDebtorsSummary();
      expect(service.getDebtors).toHaveBeenCalled();
    });

    it('should call casedebtor details', () => {
      jest.spyOn(component, 'concateReferenceNo');
      component.getCaseDebtorDetails();
      expect(component.request).not.toBeNull();
      expect(component.canFetchOpenItem).toBeFalsy();
      expect(service.getDebtors).toHaveBeenCalled();
    });

    it('should call case changeddebtor details', () => {
      component.openItemRequest = {
        ItemEntityId: 1234,
        ItemTransactionId: -34534
      };
      component.getOpenItemDebtorDetails();
      expect(component.request).not.toBeNull();
      expect(component.canFetchOpenItem).toBeFalsy();
      expect(service.getOpenItemDebtors).toHaveBeenCalled();
    });

    it('should call fetchDebtorsGridData details', () => {
      component.openItemRequest = {
        ItemEntityId: 1234,
        ItemTransactionId: -34534
      };
      component.canFetchExistingRecords = false;
      component.canFetchOpenItem = false;
      jest.spyOn(component, 'getCaseDebtorDetails');
      component.fetchDebtorsGridData();
      expect(component.request).not.toBeNull();
      expect(component.canFetchOpenItem).toBeFalsy();
      expect(component.getCaseDebtorDetails).toHaveBeenCalled();
    });
  });

  it('should call fetchExistingRecords', () => {
    component.debtors = {
      DebtorList: [{ NameId: 234 }]
    };
    component.fetchExistingRecords();
    expect(component.canFetchExistingRecords).toBeTruthy();
    expect(component.grid.search).toHaveBeenCalled();
  });

  it('should call hasDifferentDebtors', () => {
    component.preDebtors = {
      DebtorList: [{ CaseId: 123, NameId: 632 }]
    };
    jest.spyOn(component, 'checkDiffDebtorInCaseList');
    component.canSkipWarning = { differentDebtor: false };
    const result = component.hasDifferentDebtors();
    expect(result).toBeTruthy();
  });

  it('should call hasDifferentBillToDebtor', () => {
    component.preDebtors = {
      DebtorList: [{ CaseId: 123, NameId: 632, BillToNameId: 453 }]
    };
    jest.spyOn(component, 'checkDiffDebtorInCaseList');
    component.canSkipWarning = { differentDebtor: false };
    const result = component.hasDifferentBillToDebtor();
    expect(result).toBeTruthy();
  });

  it('should call differentDebtorsWarning', fakeAsync(() => {
    component.preDebtors = {
      DebtorList: [{ CaseId: 123, NameId: 632 }]
    };
    component.canSkipWarning = { differentDebtor: false };
    component.differentDebtorsWarning();

    const model = { content: { confirmed$: of(), cancelled$: of() } };
    ipxNotificationService.openConfirmationModal.mockReturnValue(model);

    tick(10);
    model.content.confirmed$.subscribe(() => {
      expect(component.preDebtors).toEqual(component.debtors);
    });
  }));

  it('should call debtorChangedsWarning', fakeAsync(() => {
    const debtors = {
      DebtorList: [{ CaseId: 123, NameId: 632, BillToNameId: 345 }]
    };
    component.preDebtors = debtors;
    component.siteControls = { SuppressBillToPrompt: false };
    jest.spyOn(component, 'applyChangedDebtors');
    component.canSkipWarning = { differentDebtor: false };
    component.debtorChangedWarning(debtors.DebtorList);

    const model = { content: { confirmed$: of(), cancelled$: of() } };
    ipxNotificationService.openConfirmationModal.mockReturnValue(model);

    tick(10);
    model.content.confirmed$.subscribe(() => {
      expect(component.applyChangedDebtors).toHaveBeenCalled();
    });
  }));
  describe('hasWarnings', () => {
    it('hasWarnings should return true if debtor has warnings', () => {
      const dataItem = { Warnings: [{ id: 1, warning: 'Draft bills exit' }] };
      const hasWarnings = component.hasWarnings(dataItem);
      expect(hasWarnings).toBe(true);
    });
    it('hasWarnings should return true if debtor has discounts', () => {
      const dataItem = { Warnings: [], Discounts: [{ id: 1, discount: 10 }] };
      const hasWarnings = component.hasWarnings(dataItem);
      expect(hasWarnings).toBe(true);
    });
    it('hasWarnings should return true if debtor doesnt allow multiple cases', () => {
      component.request = { casesCount: 1 };
      const dataItem = { Warnings: [], Discounts: [], IsMultiCaseAllowed: false };
      let hasWarnings = component.hasWarnings(dataItem);
      expect(hasWarnings).toBe(false);

      component.request.casesCount = 2;
      hasWarnings = component.hasWarnings(dataItem);
      expect(hasWarnings).toBe(true);
    });
  });
  it('hasInstructions should return true if debtor has instructions', () => {
    const dataItem = { Instructions: 'abcd' };
    const hasInstructions = component.hasInstructions(dataItem);
    expect(hasInstructions).toBe(true);
  });
  it('should call showActivityWarnings for onAction Change', () => {
    component.changeActivity(ActivityEnum.onActionChanged, { key: 123, code: 'EB' });
    jest.spyOn(component, 'onActionChangeWarning');
    jest.spyOn(component, 'onRenewalCheckChangeWarning');
    jest.spyOn(component, 'differentDebtorsWarning');
    jest.spyOn(component, 'hasDifferentBillToDebtor').mockReturnValue(true);

    component.canSkipWarning = { differentDebtor: false };
    component.showActivityWarnings();
    expect(component.onActionChangeWarning).toHaveBeenCalled();
    expect(component.onRenewalCheckChangeWarning).not.toHaveBeenCalled();
    expect(component.differentDebtorsWarning).not.toHaveBeenCalled();
  });

  it('should call showActivityWarnings for renewal check Change', () => {
    component.debtors = {
      DebtorList: [{ CaseId: 123, NameId: 632, BillToNameId: 345 }]
    };
    component.changeActivity(ActivityEnum.onRenewalFlagChanged);
    jest.spyOn(component, 'onActionChangeWarning');
    jest.spyOn(component, 'onRenewalCheckChangeWarning');
    jest.spyOn(component, 'differentDebtorsWarning');
    jest.spyOn(component, 'hasDifferentDebtors').mockReturnValue(true);

    component.canSkipWarning = { differentDebtor: false };
    component.showActivityWarnings();
    expect(component.onActionChangeWarning).not.toHaveBeenCalled();
    expect(component.onRenewalCheckChangeWarning).toHaveBeenCalled();
    expect(component.differentDebtorsWarning).not.toHaveBeenCalled();
  });

  it('should call loadDebtorsOnRenewalFlagChange', () => {
    component.changeActivity(ActivityEnum.onRenewalFlagChanged);
    component.canSkipWarning = { differentDebtor: false };
    component.loadDebtorsOnRenewalFlagChange();
    expect(component.canSkipWarning).toEqual({ differentDebtor: false, changedDebtor: false });
    expect(component.canFetchExistingRecords).toBeFalsy();
    expect(component.activity.onRenewalFlagChanged).toEqual({});
  });

  it('should call openDebtorDiscounts', () => {
    const debtor = { Discounts: [{ DiscountRate: 50, WipCode: 'Code', Country: 'Australia' }] };
    component.openDebtorDiscounts(debtor);
    expect(modalService.openModal).toHaveBeenCalled();
  });

  it('should get ActingAsDebtor', () => {
    component.preDebtors = {
      DebtorList: [{ NameId: 123, AttentionName: 'Atten', ReferenceNo: '23412', Address: 'Addresss', NameTypeDescription: 'Debtor', DiscountRate: 50 }]
    };
    component.getActingAsDebtor();
    expect(component.uniqueDebtors).toEqual(component.preDebtors.DebtorList);
  });

  it('should get FormatNameTypeBillPercentageDisplay', () => {
    const debtor = { NameTypeDescription: 'Debtor', BillPercentage: 50, WipCode: 'Code', Country: 'Australia' };
    const result = component.getFormatNameTypeBillPercentageDisplay(debtor);
    expect(result).toBe('Debtor (50 %)');
  });
  it('should check for different debtors when debtor changed after manual entry', fakeAsync(() => {
    component.preDebtors = {
      DebtorList: [{ NameId: 900, AttentionName: 'Atten', ReferenceNo: '23412', Address: 'Addresss', NameTypeDescription: 'Debtor', DiscountRate: 50 }]
    };
    jest.spyOn(component, 'showActivityWarnings');
    component.hasDebtorChangedManually = true;
    const model = { content: { confirmed$: of(), cancelled$: of() } };
    ipxNotificationService.openConfirmationModal.mockReturnValue(model);
    component.confirmDebtorChangeAfterUserEnteredDebtor();
    tick(500);
    expect(ipxNotificationService.openConfirmationModal).toBeCalledWith('accounting.billing.step1.confirmTitle', 'accounting.billing.confirmDebtorChange');
    model.content.confirmed$.subscribe(() => {
      expect(component.hasDebtorChangedManually).toBe(false);
      expect(component.showActivityWarnings).toBeCalled();
    });
  }));
  it('should check for different debtors when debtor changed after manual entry', () => {
    component.preDebtors = {
      DebtorList: [{ NameId: 900, AttentionName: 'Atten', ReferenceNo: '23412', Address: 'Addresss', NameTypeDescription: 'Debtor', DiscountRate: 50 }]
    };
    component.changeActivity(ActivityEnum.onRenewalFlagChanged);
    component.canSkipWarning = { differentDebtor: false };
    jest.spyOn(component, 'showActivityWarnings');
    component.hasDebtorChangedManually = false;
    component.confirmDebtorChangeAfterUserEnteredDebtor();
    expect(component.showActivityWarnings).toBeCalled();
  });

  it('should get concateReferenceNo', () => {
    component.debtors = {
      DebtorList: [{ NameId: 123, AttentionName: 'Atten', ReferenceNo: '23412', Address: 'Addresss', NameTypeDescription: 'Debtor', DiscountRate: 50 }]
    };
    component.gridOptions = {};
    component.gridOptions = {
      columns: []
    };
    const res = component.debtors.DebtorList;
    billingService.originalDebtorList$.next(res);
    component.concateReferenceNo();
    expect(component.debtors.DebtorList[0].ReferenceNo).toEqual('23412');
  });
});
