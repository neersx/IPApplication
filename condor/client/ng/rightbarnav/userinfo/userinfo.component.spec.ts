import { AppContextServiceMock } from 'core/app-context.service.mock';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { UserInfoComponent } from './userinfo.component';

describe('UserinfoComponent', () => {
  let component: UserInfoComponent;

  beforeEach(() => {
    component = new UserInfoComponent(new AppContextServiceMock() as any, new ModalServiceMock() as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});