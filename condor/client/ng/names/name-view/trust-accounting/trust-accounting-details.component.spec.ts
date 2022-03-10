import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { NameViewServiceMock } from '../name-view.service.mock';
import { TrustAccountingDetailsComponent } from './trust-accounting-details.component';

describe('TrustAccountingComponent', () => {
  let component: TrustAccountingDetailsComponent;
  const serviceMock = new NameViewServiceMock();
  let modalService: ModalServiceMock;
  let localSettings: LocalSettingsMock;

  beforeEach(() => {
    modalService = new ModalServiceMock();
    localSettings = new LocalSettingsMock();
    component = new TrustAccountingDetailsComponent(modalService as any, serviceMock as any, localSettings as any);
  });

  it('should create and initialise the modal', () => {
    component.ngOnInit();
    expect(component).toBeDefined();
    expect(component.gridOptions).toBeDefined();
  });
});