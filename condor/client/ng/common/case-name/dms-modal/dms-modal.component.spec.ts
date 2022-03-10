import { BsModalRefMock } from 'mocks';
import { DmsModalComponent } from './dms-modal.component';

describe('DmsModalComponent', () => {
  let component: DmsModalComponent;
  let modalRef: BsModalRefMock;
  beforeEach(() => {
    modalRef = new BsModalRefMock();
    component = new DmsModalComponent(modalRef);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should close on ok', () => {
    component.close();

    expect(modalRef.hide).toHaveBeenCalled();
  });
});
