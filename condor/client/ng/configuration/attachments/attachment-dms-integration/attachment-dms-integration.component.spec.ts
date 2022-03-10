import { assert } from 'console';
import { StateServiceMock } from 'mocks';
import { AttachmentConfigurationServiceMock } from '../attachments-configuration.service.mock';
import { AttachmentDmsIntegrationComponent } from './attachment-dms-integration.component';

describe('AttachmentDmsIntegrationComponent', () => {
  let component: AttachmentDmsIntegrationComponent;
  let service: AttachmentConfigurationServiceMock;
  let stateService: any;

  beforeEach(() => {
    service = new AttachmentConfigurationServiceMock();
    stateService = new StateServiceMock();
    component = new AttachmentDmsIntegrationComponent(service as any, stateService);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should set value correctly', () => {
    component.topic = {
      params: {
        viewData: {
          hasDmsSettings: true,
          enableDms: null
        }
      }
    } as any;
    component.ngOnInit();
    expect(component.isDmsEnabled).toBeTruthy();
  });

  it('should change status', () => {
    component.topic = {
      params: {
        viewData: {
          hasDmsSettings: true,
          enableDms: true
        }
      }
    } as any;
    component.ngOnInit();
    component.changeStatus(false as any);
    expect(component.topic.hasChanges).toBeTruthy();
    expect(component.enableChanged).toBeTruthy();
  });

  it('should go to dms state', () => {
    component.navigateToDmsConfiguration();
    expect(stateService.go).toHaveBeenCalledWith('dmsIntegration', {});
  });
});
