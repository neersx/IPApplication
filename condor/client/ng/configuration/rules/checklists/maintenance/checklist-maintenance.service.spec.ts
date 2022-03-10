import { HttpClientMock } from 'mocks';
import { ChecklistMaintenanceService } from './checklist-maintenance.service';

describe('Service: ChecklistMaintenance', () => {
    let service: ChecklistMaintenanceService;
    let http: any;
    beforeEach(() => {
        http = new HttpClientMock();
        service = new ChecklistMaintenanceService(http);
    });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });
});
