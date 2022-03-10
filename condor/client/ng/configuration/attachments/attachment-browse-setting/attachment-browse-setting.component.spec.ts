import { AttachmentConfigurationServiceMock } from '../attachments-configuration.service.mock';
import { AttachmentBrowseSettingComponent } from './attachment-browse-setting.component';

describe('AttachmentBrowseSettingComponent', () => {
  let component: AttachmentBrowseSettingComponent;
  let service: AttachmentConfigurationServiceMock;

  beforeEach(() => {
    service = new AttachmentConfigurationServiceMock();
    component = new AttachmentBrowseSettingComponent(service as any);
    component.topic = {
      params: {
        viewData: {
          enableBrowseButton: true
        }
      }
    } as any;
    component.ngOnInit();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should set value correctly', () => {
    expect(component.enableBrowseButton).toBeTruthy();
  });

  it('should change status', () => {
    component.changeStatus(false as any);
    expect(component.topic.hasChanges).toBeTruthy();
    expect(component.enableChanged).toBeTruthy();
  });
});
