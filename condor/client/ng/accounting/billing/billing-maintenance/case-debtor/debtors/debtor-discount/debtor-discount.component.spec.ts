
import { BsModalRefMock, ChangeDetectorRefMock } from 'mocks';
import { DebtorDiscountComponent } from './debtor-discount.component';

describe('DebtorDiscountComponent', () => {
  let component: DebtorDiscountComponent;
  let cdr: ChangeDetectorRefMock;
  let modalRef: BsModalRefMock;
  beforeEach(() => {
    cdr = new ChangeDetectorRefMock();
    modalRef = new BsModalRefMock();
    component = new DebtorDiscountComponent(cdr as any, modalRef as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should initialize component', () => {
    jest.spyOn(component, 'buildGridOptions');
    component.ngOnInit();
    expect(component.buildGridOptions).toHaveBeenCalled();
  });

  it('should cancel modal', () => {
    component.cancel();
    expect(modalRef.hide).toHaveBeenCalled();
  });
});
