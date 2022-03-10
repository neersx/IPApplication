import { FormBuilder } from '@angular/forms';
import { BsModalRefMock, ChangeDetectorRefMock, GridNavigationServiceMock, IpxNotificationServiceMock } from 'mocks';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { MaintainKeywordsComponent } from './maintain-keywords.component';

describe('MaintainKeywordsComponent', () => {
  let component: MaintainKeywordsComponent;
  let ipxNotificationService: IpxNotificationServiceMock;
  let bsModal: BsModalRefMock;
  const fb = new FormBuilder();
  let cdr: ChangeDetectorRefMock;
  let navService: GridNavigationServiceMock;
  let shortcutsService: IpxShortcutsServiceMock;
  let destroy$: any;

  const service = {
    getKeywordsList: jest.fn().mockReturnValue(of({})),
    submitKeyWord: jest.fn().mockReturnValue(of({})),
    getKeyWordDetails: jest.fn().mockReturnValue(of({}))
  };

  beforeEach(() => {
    ipxNotificationService = new IpxNotificationServiceMock();
    bsModal = new BsModalRefMock();
    navService = new GridNavigationServiceMock();
    cdr = new ChangeDetectorRefMock();
    shortcutsService = new IpxShortcutsServiceMock();
    destroy$ = of({}).pipe(delay(1000));

    component = new MaintainKeywordsComponent(service as any, cdr as any,
      ipxNotificationService as any, bsModal as any,
      fb, navService as any, destroy$, shortcutsService as any);
    component.navData = {
      keys: [{ value: 1 }],
      totalRows: 3,
      pageSize: 10,
      fetchCallback: jest.fn().mockReturnValue({ keys: [{ value: 1 }, { value: 4 }, { value: 31 }] })
    };
    component.onClose$.next = jest.fn() as any;
    component.form = {
      reset: jest.fn(),
      value: {},
      valid: false,
      dirty: false
    };
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should set formData', () => {
    const data = {
      keywordNo: 1,
      keyword: undefined,
      caseStopWord: true,
      nameStopWord: false,
      synonyms: null
    };
    component.form = { setValue: jest.fn() };
    component.setFormData(data);
    expect(component.form.setValue).toBeCalledWith(data);
  });

  it('should create new formGroup', () => {
    component.createFormGroup();
    expect(component.form).not.toBeNull();
  });

  it('should submit formData', () => {
    const result = {
      keywordNo: 1,
      keyword: 'Abc',
      caseStopWord: true,
      nameStopWord: false
    };
    component.form = {
      value: result,
      valid: true,
      dirty: true
    };
    component.submit();
    expect(component.form).not.toBeNull();
  });

  it('should discard changes', () => {
    component.form = {
      dirty: true
    };
    component.cancel();
    expect(component.form).not.toBeNull();
    component.sbsModalRef.content.confirmed$.subscribe(() => {
      expect(component.form).not.toBeNull();
    });
  });

  it('should reset form', () => {
    component.resetForm();
    expect(component.onClose$.next).toHaveBeenCalledWith(false);
    expect(bsModal.hide).toHaveBeenCalled();
    expect(component.form.reset).toBeCalled();
  });

  it('should get next keyword details', () => {
    component.form = {
      markAsPristine: jest.fn()
    };
    component.getNextKeywordDetails(1);
    expect(component.id).toBe(1);
    expect(component.form.markAsPristine).toBeCalled();
  });

});
