import { FormBuilder } from '@angular/forms';
import { CaseBillNarrativeComponent } from 'accounting/time-recording/case-bill-narrative/case-bill-narrative.component';
import { WarningCheckerServiceMock, WarningServiceMock } from 'accounting/warnings/warning.mock';
import { ChangeDetectorRefMock, IpxNotificationServiceMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { WindowParentMessagingServiceMock } from 'mocks/window-parent-messaging.service.mock';
import { BehaviorSubject, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { SplitWipHeaderComponent } from './split-wip-header.component';
import { SplitWipHelper } from './split-wip-helper';
import { SplitWipComponent } from './split-wip.component';
import { SplitWipData, SplitWipType } from './split-wip.model';

describe('SplitWipComponent', () => {
  let component: SplitWipComponent;
  let cdr: ChangeDetectorRefMock;
  let notificationService: NotificationServiceMock;
  let ipxNotificationService: IpxNotificationServiceMock;
  let translate: TranslateServiceMock;
  let fb: FormBuilder;
  let destroy$: any;
  let warningChecker: WarningCheckerServiceMock;
  let windowParentMessagingService: WindowParentMessagingServiceMock;
  let warningService: WarningServiceMock;
  let modalService: ModalServiceMock;
  const datePipe = {
    transform: jest.fn().mockReturnValue(new Date())
  };

  const service = {
    getWipSupportData$: jest.fn().mockReturnValue(of({ splitWipMultiDebtor: true, wipWriteDownRestricted: true })),
    getItemForSplitWip$: jest.fn().mockReturnValue(of({ foreignCurrency: true, foreignBalance: 100, localDeciamlPlaces: 2, foreignDecimalPlaces: 2 })),
    hasMultipleDebtors$: jest.fn().mockReturnValue(of({})),
    validateItemDate: jest.fn().mockReturnValue(of({
      HasError: true,
      ValidationErrorList: [{
        ErrorCode: 'AC124'
      }]
    }))
  };

  beforeEach(() => {
    fb = new FormBuilder();
    windowParentMessagingService = new WindowParentMessagingServiceMock();
    notificationService = new NotificationServiceMock();
    warningChecker = new WarningCheckerServiceMock();
    ipxNotificationService = new IpxNotificationServiceMock();
    warningService = new WarningServiceMock();
    translate = new TranslateServiceMock();
    cdr = new ChangeDetectorRefMock();
    destroy$ = of({}).pipe(delay(1000));
    modalService = new ModalServiceMock();
    component = new SplitWipComponent(service as any, cdr as any, notificationService as any, ipxNotificationService as any, translate as any, fb, destroy$, warningChecker as any, windowParentMessagingService as any, datePipe as any, warningService as any, modalService as any);
    const elementMock = {
      clearValue: jest.fn(),
      showError$: { next: jest.fn() },
      el: {
        nativeElement: {
          querySelector: jest.fn().mockReturnValue({
            click: jest.fn()
          })
        }
      }
    };
    component.percentCtrl = elementMock;
    component.amountCtrl = elementMock;
    component.grid = {
      checkChanges: jest.fn(),
      closeEditedRows: jest.fn(),
      isValid: jest.fn(),
      isDirty: jest.fn(),
      wrapper: {
        data: [
          {
            amount: 500,
            splitPercent: 50,
            localValue: 500,
            foreignValue: null,
            balance: 500,
            case: {},
            name: {},
            staff: {},
            id: 0,
            status: 'A'
          }
        ]
      }
    } as any;

    component.splitWipheader = new SplitWipHeaderComponent(translate as any);
    const wipData: SplitWipData = {
      localAmount: 500,
      foreignBalance: 50,
      localValue: 500,
      foreignValue: null,
      caseReference: '1234',
      staffName: 'staff',
      narrativeCode: 'N',
      narrativeKey: 5,
      wipCategoryCode: 'W',
      wipDescription: 'Description',
      wipCode: 'AC',
      wipSeqKey: 1,
      entityKey: 123456,
      responsibleName: '',
      balance: 500,
      isCreditWip: false,
      localCurrency: 'AUD',
      exchRate: 1.5,
      localDeciamlPlaces: 2,
      foreignDecimalPlaces: 2,
      transDate: new Date(),
      transKey: 123,
      responsibleNameCode: 'RS'
    };
    component.splitWipData = wipData;
    component.splitWipHelper = new SplitWipHelper(wipData);
    const splitWipItem = { amount: 500, splitPercent: 50, localValue: 500 };
    component.activeDataItem = splitWipItem;
    jest.spyOn(component, 'getValidRows').mockReturnValue([splitWipItem]);
    component.originalAmount = 1000;
    component.form = {
      markAsDirty: jest.fn(),
      reset: jest.fn(),
      value: {},
      valid: false,
      dirty: false,
      controls: {
        case: {
          markAsTouched: jest.fn(),
          setErrors: jest.fn(),
          value: { key: 'Acb', code: 'Acb', value: 'Abc Value' }
        },
        amount: {
          markAsTouched: jest.fn(),
          markAsPristine: jest.fn(),
          setErrors: jest.fn(),
          value: 100
        },
        localValue: {
          markAsTouched: jest.fn(),
          markAsPristine: jest.fn(),
          setErrors: jest.fn(),
          value: 10
        },
        name: {
          markAsTouched: jest.fn(),
          markAsPristine: jest.fn(),
          setErrors: jest.fn()
        },
        foreignValue: {
          markAsTouched: jest.fn(),
          markAsPristine: jest.fn(),
          setErrors: jest.fn()
        },
        staff: {
          markAsTouched: jest.fn(),
          markAsPristine: jest.fn(),
          setErrors: jest.fn()
        },
        splitPercent: {
          markAsTouched: jest.fn(),
          markAsPristine: jest.fn(),
          setErrors: jest.fn()
        },
        profitCentre: {
          markAsTouched: jest.fn(),
          markAsPristine: jest.fn(),
          setErrors: jest.fn()
        },
        narrative: {
          markAsTouched: jest.fn(),
          markAsPristine: jest.fn(),
          setErrors: jest.fn()
        },
        debitNoteText: {
          markAsPristine: jest.fn(),
          markAsTouched: jest.fn(),
          setErrors: jest.fn(),
          markAsDirty: jest.fn(),
          value: '',
          invalid: false
        }
      }
    };
    component.viewData = {
      WipWriteDownRestricted: true,
      WriteDownLimit: true
    };
    component.caseEl = elementMock;
    component.nameEl = elementMock;
    component.staffEl = elementMock;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should initialize component', () => {
    jest.spyOn(component, 'getSplitWipDetails');
    component.ngOnInit();
    service.getWipSupportData$().subscribe(res => {
      expect(res).toBeDefined();
      expect(component.viewData).toBe(res);
    });
  });

  it('should render ui', () => {
    jest.spyOn(component, 'getSplitWipDetails');
    component.ngAfterViewInit();
    expect(component.getSplitWipDetails).toHaveBeenCalled();
  });

  it('should get Split Wip details', () => {
    component.getSplitWipDetails();
    service.getItemForSplitWip$().subscribe(res => {
      expect(res).toBeDefined();
      expect(component.splitWipData).toBe(res);
    });
  });
  describe('On imput control Field Changes', () => {
    it('should allocate amount on allocatermainder click', () => {
      component.form = {
        markAsDirty: jest.fn(),
        patchValue: jest.fn(),
        controls: {
          amount: {
            markAsTouched: jest.fn(),
            markAsPristine: jest.fn(),
            setErrors: jest.fn(),
            setValue: jest.fn(),
            value: 100
          },
          splitPercent: {
            markAsTouched: jest.fn(),
            markAsDirty: jest.fn(),
            setErrors: jest.fn(),
            setValue: jest.fn(),
            value: 100
          }
        }
      };
      jest.spyOn(component, 'setAmount');
      jest.spyOn(component, 'setPercentage');
      component.onAllocateRemainder();
      expect(component.setAmount).toHaveBeenCalled();
      expect(component.form.markAsDirty).toHaveBeenCalled();
    });

    it('should allocate amount on onAmountChange', () => {
      component.form = {
        markAsDirty: jest.fn(),
        patchValue: jest.fn(),
        controls: {
          amount: {
            markAsDirty: jest.fn(),
            markAsTouched: jest.fn(),
            markAsPristine: jest.fn(),
            setErrors: jest.fn(),
            setValue: jest.fn(),
            value: 100
          },
          splitPercent: {
            markAsDirty: jest.fn(),
            markAsTouched: jest.fn(),
            markAsPristine: jest.fn(),
            setErrors: jest.fn(),
            setValue: jest.fn(),
            value: 10
          }
        }
      };
      jest.spyOn(component, 'setAmount');
      jest.spyOn(component, 'setPercentage');
      jest.spyOn(component, 'checkErrorState');
      component.onAmountChange(100);
      expect(component.setPercentage).toHaveBeenCalled();
      expect(component.checkErrorState).toHaveBeenCalled();
    });

    it('should allocate amount on onPercentChange', () => {
      component.form = {
        markAsDirty: jest.fn(),
        patchValue: jest.fn(),
        controls: {
          amount: {
            markAsTouched: jest.fn(),
            setValue: jest.fn(),
            markAsPristine: jest.fn(),
            setErrors: jest.fn(),
            value: 100
          },
          splitPercent: {
            markAsPristine: jest.fn(),
            setValue: jest.fn(),
            setErrors: jest.fn()
          }
        }
      };
      jest.spyOn(component, 'setPercent');
      jest.spyOn(component, 'checkErrorState');
      component.onPercentageChange(50);
      expect(component.setPercent).not.toHaveBeenCalled();
      component.splitByType = SplitWipType.percentage;
      component.onPercentageChange(60);
      expect(component.setPercent).toHaveBeenCalled();
      expect(component.form.controls.amount.setValue).toHaveBeenCalled();
      expect(component.checkErrorState).toHaveBeenCalled();
    });

    it('should call the warningChecker oncaseChange', done => {
      warningChecker.performCaseWarningsCheckResult = of(true);
      const event = { key: 123 };
      component.onCaseChange(event);
      warningChecker.performCaseWarningsCheck(event, new Date()).subscribe((result) => {
        expect(result).toBeTruthy();
        done();
      });
    });

    it('should call the warningChecker onNameChange', done => {
      warningChecker.performCaseWarningsCheckResult = of(true);
      const event = { key: 123 };
      component.onNameChange(event);
      warningChecker.performCaseWarningsCheck(event, new Date()).subscribe((result) => {
        expect(result).toBeTruthy();
        done();
      });
    });

    it('should call the onStaffChange', () => {
      component.form = {
        controls: {
          profitCentre: {
            setValue: jest.fn()
          }
        }
      };
      jest.spyOn(component, 'applyDefaultProfitCentre');
      jest.spyOn(component, 'validateStaff');
      const event = { key: 123 };
      component.onStaffChange(event);
      expect(component.applyDefaultProfitCentre).toHaveBeenCalled();
    });

    it('should call the onNarrativeChange', () => {
      component.form = {
        controls: {
          debitNoteText: {
            setValue: jest.fn()
          }
        }
      };
      jest.spyOn(component, 'validateStaff');
      const event = { text: 'Narrative' };
      component.onNarrativeChange(event);
      expect(component.form.controls.debitNoteText.setValue).toHaveBeenCalledWith(event.text);
    });

    it('should check if case has multiple debtors', (done) => {
      component.form = {
        controls: {
          debitNoteText: {
            setValue: jest.fn()
          }
        }
      };
      jest.spyOn(service, 'hasMultipleDebtors$').mockReturnValue(of(true));
      component.caseHasMultiDebtors(123);
      service.hasMultipleDebtors$().subscribe(res => {
        expect(res).toBeTruthy();
        expect(component.hasMultipleDebtors).toBeTruthy();
        done();
      });
    });

    it('should call the clearCaseDefault', () => {
      component.form = {
        controls: {
          name: {
            setValue: jest.fn()
          },
          staff: {
            setValue: jest.fn()
          },
          profitCentre: {
            setValue: jest.fn()
          }
        }
      };
      component.clearCaseDefaultedFields();
      expect(component.form.controls.name.setValue).toHaveBeenCalledWith(null);
      expect(component.form.controls.staff.setValue).toHaveBeenCalledWith(null);
      expect(component.form.controls.profitCentre.setValue).toHaveBeenCalledWith(null);
    });
  });
  it('should get the splitwipdetails from api', (done) => {
    component.grid = {
      checkChanges: jest.fn(),
      closeEditedRows: jest.fn(),
      isValid: jest.fn(),
      isDirty: jest.fn(),
      addRow: jest.fn()
    } as any;

    jest.spyOn(component, 'buildGridOptions');
    component.getSplitWipDetails();
    service.getItemForSplitWip$().subscribe(res => {
      expect(res).toBeDefined();
      expect(component.isForeignCurrency).toBeTruthy();
      expect(component.originalAmount).toBe(res.foreignBalance);
      expect(component.decimalPlaces).toBe(res.foreignDecimalPlaces);
      expect(component.buildGridOptions).toHaveBeenCalled();
      setTimeout(() => {
        expect(component.grid.addRow).toHaveBeenCalled();
        expect(component.splitWipheader.unallocatedAmount.next).toHaveBeenCalled();
      }, 200);
      done();
    });
  });

  it('should call the changeSplitBy', () => {
    component.form = {
      controls: {
        amount: {
          setErrors: jest.fn(),
          clearValidators: jest.fn(),
          updateValueAndValidity: jest.fn()
        },
        splitPercent: {
          setErrors: jest.fn(),
          clearValidators: jest.fn(),
          updateValueAndValidity: jest.fn(),
          setValidators: jest.fn()
        }
      }
    };
    jest.spyOn(component, 'processSplitBy');
    jest.spyOn(component, 'navigateFromEqually');
    const splitBy = SplitWipType.percentage;
    component.changeSplitBy(splitBy);
    expect(component.processSplitBy).toHaveBeenCalled();
    expect(component.navigateFromEqually).toHaveBeenCalled();
    expect(component.oldSplitByType).toBe(splitBy);
  });

  it('should call the processSplitBy', () => {
    component.form = {
      controls: {
        amount: {
          setErrors: jest.fn(),
          clearValidators: jest.fn(),
          updateValueAndValidity: jest.fn()
        },
        splitPercent: {
          setErrors: jest.fn(),
          clearValidators: jest.fn(),
          updateValueAndValidity: jest.fn(),
          setValidators: jest.fn()
        }
      }
    };
    jest.spyOn(component, 'processSplitBy');
    jest.spyOn(component, 'navigateFromEqually');
    jest.spyOn(component, 'isTotalAmountAllocated').mockReturnValue(true);
    const splitBy = SplitWipType.percentage;
    component.processSplitBy(splitBy);
    expect(component.isTotalAmountAllocated).toBeTruthy();
    expect(component.isAmountDisabled).toBeTruthy();
    expect(component.isPercentageDisabled).toBeFalsy();
    expect(component.navigateFromEqually).toHaveBeenCalled();
    expect(component.oldSplitByType).toBe(splitBy);
  });

  it('should call the splitItemsEqually', () => {
    component.form = {
      dirty: true,
      controls: {
        splitPercent: {
          setErrors: jest.fn(),
          setValue: jest.fn(),
          markAsPristine: jest.fn()
        },
        amount: {
          setErrors: jest.fn(),
          setValue: jest.fn(),
          markAsPristine: jest.fn()
        }
      }
    };
    jest.spyOn(component, 'setAmount');
    jest.spyOn(component, 'setPercent');
    jest.spyOn(component.splitWipHelper, 'splitItemsEqually');
    component.isAdding = true;
    component.disableAll = false;
    component.splitItemsEqually();
    expect(component.setAmount).toHaveBeenCalled();
    expect(component.setPercent).toHaveBeenCalled();
    expect(component.splitWipHelper.splitItemsEqually).toHaveBeenCalled();
  });

  it('should call the navigateFromEqually', () => {
    component.form = {
      dirty: true,
      reset: jest.fn(),
      controls: {
        splitPercent: {
          setErrors: jest.fn(),
          setValue: jest.fn(),
          markAsPristine: jest.fn()
        },
        amount: {
          setErrors: jest.fn(),
          setValue: jest.fn(),
          markAsPristine: jest.fn()
        }
      }
    };
    component.grid = {
      checkChanges: jest.fn(),
      closeEditedRows: jest.fn(),
      isValid: jest.fn(),
      isDirty: jest.fn(),
      addRow: jest.fn(),
      wrapper: {
        data: [
          {
            amount: 500,
            splitPercent: 50,
            localValue: 500,
            foreignValue: null,
            balance: 500,
            case: {},
            name: {},
            staff: {},
            id: 0,
            status: 'A'
          }
        ]
      }
    } as any;
    jest.spyOn(component, 'removeAddedEmptyRow');
    jest.spyOn(component, 'reset');
    component.oldSplitByType = SplitWipType.equally;

    component.navigateFromEqually();
    expect(component.removeAddedEmptyRow).toHaveBeenCalled();
    expect(component.reset).toHaveBeenCalled();
    expect(component.grid.addRow).toHaveBeenCalled();
  });

  it('should call the onRowEdited', () => {
    const data = {
      rowIndex: 1,
      status: rowStatus.Adding,
      dataItem: {
        amount: 500,
        splitPercent: 50,
        localValue: 500,
        foreignValue: null,
        profitCentre: null,
        exchRate: 1,
        balance: 500,
        case: {},
        name: {},
        staff: {},
        debitNoteText: '',
        id: 0,
        narrative: null,
        status: 'A'
      }
    };

    component.form = {
      dirty: true,
      reset: jest.fn(),
      controls: {
        profitCentre: {
          setErrors: jest.fn(),
          setValue: jest.fn(),
          markAsPristine: jest.fn()
        },
        splitPercent: {
          setErrors: jest.fn(),
          setValue: jest.fn(),
          markAsPristine: jest.fn()
        },
        amount: {
          setErrors: jest.fn(),
          setValue: jest.fn(),
          markAsPristine: jest.fn()
        }
      }
    };

    jest.spyOn(component, 'removeAddedEmptyRow');
    jest.spyOn(component, 'reset');
    jest.spyOn(component, 'initializeDataItem');
    jest.spyOn(component, 'clearForm');
    jest.spyOn(component, 'setFormData');
    component.onRowEdited(data);
    expect(component.removeAddedEmptyRow).toHaveBeenCalled();
    expect(component.initializeDataItem).toHaveBeenCalled();
    expect(component.clearForm).toHaveBeenCalled();
    expect(component.setFormData).toHaveBeenCalled();
    expect(component.activeDataItem).toBe(data.dataItem);
    expect(component.disableAll).toBe(false);
  });

  it('should call the initializeDataItem', () => {
    const data = {
      rowIndex: 1,
      status: rowStatus.Adding,
      dataItem: {
        amount: 500,
        splitPercent: 50,
        localValue: 500,
        foreignValue: null,
        balance: 500,
        case: {},
        name: {},
        staff: {},
        id: 0,
        status: 'A'
      }
    };

    component.initializeDataItem(data);
    expect(component.activeIndex).toBe(data.rowIndex);
    expect(component.activeDataItem).toBe(data.dataItem);
    expect(component.isAdding).toBe(true);
  });

  it('should call the submit data', () => {

    const response = {
      HasError: true,
      ValidationErrorList: [{
        ErrorCode: 'AC124'
      }]
    };
    component.splitWipheader = {
      reasonForm: {
        control: {
          controls: {
            reason: {
              errors: null
            }
          }
        }
      }
    };

    jest.spyOn(service, 'validateItemDate').mockReturnValue(of(response));
    component.submit();

    service.validateItemDate(new Date()).subscribe(res => {
      expect(res).toBeDefined();
      expect(res.hasError).toBeTruthy();
    });

  });

  it('should close form if form is not dirty', () => {
    component.form.dirty = false;
    component.splitWipheader = {
      reason: null
    };
    ipxNotificationService.openDiscardModal.mockReturnValue({ content: { confirmed$: new BehaviorSubject('') } });
    component.validRows = [{ case: 123, id: 1 }];
    jest.spyOn(component, 'discardAndClear');
    component.closeModal();
    expect(component.discardAndClear).toHaveBeenCalled();
  });

  it('should give confirmation dialog if form is dirty', () => {
    component.form.dirty = true;
    ipxNotificationService.openDiscardModal.mockReturnValue({ content: { confirmed$: new BehaviorSubject('') } });
    component.closeModal();
    expect(ipxNotificationService.openDiscardModal).toHaveBeenCalled();
  });

  it('should discard changes and clear form', () => {
    component.form.dirty = true;
    ipxNotificationService.openDiscardModal.mockReturnValue({ content: { confirmed$: new BehaviorSubject('') } });
    component.discardAndClear();
    expect(windowParentMessagingService.postLifeCycleMessage).toHaveBeenCalled();
  });

  it('should check if save is disabled', () => {
    component.form.dirty = true;
    component.originalAmount = 200;
    jest.spyOn(component.splitWipHelper, 'totalAllocatedAmount').mockReturnValue(100);
    component.validRows = [{ case: 123, id: 1 }];
    const result = component.isSaveDisabled();
    expect(result).toBe(true);
  });

  it('should check if numeric control shows error', () => {
    component.form = {
      dirty: true,
      reset: jest.fn(),
      touched: true,
      controls: {
        splitPercent: {
          errors: { invalid: true },
          setErrors: jest.fn(),
          setValue: jest.fn(),
          markAsPristine: jest.fn()
        },
        amount: {
          setErrors: jest.fn(),
          setValue: jest.fn(),
          markAsPristine: jest.fn(),
          errors: { invalid: true }
        }
      }
    };

    const result = component.checkErrorState();
    expect(component.amountCtrl.showError$.next).toHaveBeenCalledWith(true);
    expect(component.percentCtrl.showError$.next).toHaveBeenCalledWith(true);
    expect(result).toBe(false);
  });
  describe('case narrative', () => {
    it('displays the maintain case narratives dialog', () => {
      component.form = {
        get: jest.fn().mockReturnValue({ value: { key: 10 } })
      };
      component.openCaseNarrative();

      expect(modalService.openModal).toHaveBeenCalledWith(CaseBillNarrativeComponent, {
        focus: true,
        animated: false,
        backdrop: 'static',
        class: 'modal-lg',
        initialState: { caseKey: 10 }
      });
    });
  });
});
