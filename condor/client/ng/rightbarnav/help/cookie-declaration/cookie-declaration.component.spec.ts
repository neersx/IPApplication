import { BsModalServiceMock } from 'mocks';
import { CookieDeclarationComponent } from './cookie-declaration.component';

describe('CookieDeclarationComponent', () => {
  let component: CookieDeclarationComponent;
  let bsModalMock: BsModalServiceMock;
  beforeEach(() => {
    bsModalMock = new BsModalServiceMock();
    component = new CookieDeclarationComponent(bsModalMock as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should hide the modal on close', () => {
    component.close();
    expect(bsModalMock.hide).toHaveBeenCalledWith(1);
  });
});
