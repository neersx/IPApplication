import { FormControl, FormGroup, Validators } from '@angular/forms';
import { HttpClientMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { Observable } from 'rxjs';
import { IpxPicklistMaintenanceService } from '../../ipx-picklist-maintenance.service';
import { FilePartPicklistComponent } from './file-part-picklist.component';

describe('FilePartPicklistComponent', () => {
  let c: FilePartPicklistComponent;
  const httpMock = new HttpClientMock();
  const notificationServiceMock = new NotificationServiceMock();
  let picklistMaintenanceServiceMock;
  const translateServiceMock = new TranslateServiceMock();
  const gridNavigationService = {};
  beforeEach(() => {
    picklistMaintenanceServiceMock = new IpxPicklistMaintenanceService(httpMock as any, notificationServiceMock as any, translateServiceMock as any, gridNavigationService as any);
    c = new FilePartPicklistComponent(picklistMaintenanceServiceMock);
  });

  it('should create', () => {
    expect(c).toBeTruthy();
  });

  it('should set the form after init at the time Add', () => {
    c.entry = {
      key: null,
      value: null,
      caseId: 0
    };
    c.ngOnInit();
    expect(c.form).toBeDefined();
  });

  it('should set the the modal from getEntry method', () => {
    c.entry = {};
    c.form = new FormGroup({
      value: new FormControl('Acceptance deadline', [Validators.required])
    });
    c.getEntry();
    expect(c.entry.value).toEqual('Acceptance deadline');
  });
});