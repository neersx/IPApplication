import { FormControl, FormGroup, Validators } from '@angular/forms';
import { HttpClientMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { Observable } from 'rxjs';
import { IpxPicklistMaintenanceService } from '../../ipx-picklist-maintenance.service';
import { TaskPlannerPicklistComponent } from './task-planner-picklist.component';

describe('FilePartPicklistComponent', () => {
    let c: TaskPlannerPicklistComponent;
    const httpMock = new HttpClientMock();
    const notificationServiceMock = new NotificationServiceMock();
    let picklistMaintenanceServiceMock;
    const translateServiceMock = new TranslateServiceMock();
    const gridNavigationService = {};
    beforeEach(() => {
        picklistMaintenanceServiceMock = new IpxPicklistMaintenanceService(httpMock as any, notificationServiceMock as any, translateServiceMock as any, gridNavigationService as any);
        c = new TaskPlannerPicklistComponent(picklistMaintenanceServiceMock);
    });

    it('should create', () => {
        expect(c).toBeTruthy();
    });

    it('should set the form after init at the time Add', () => {
        c.entry = {
            key: null,
            searchName: null,
            description: null,
            isPublic: null,
            presentationId: null,
            value: null,
            maintainPublicSearch: null,
            canUpdateSavedSearch: null
        };
        c.ngOnInit();
        expect(c.form).toBeDefined();
        expect(c.canUpdateSavedSearch).toEqual(null);
        expect(c.maintainPublicSearch).toEqual(null);
    });

    it('should set the form after init at the time edit', () => {
        c.entry = {
            key: 1,
            searchName: 'search',
            description: 'search',
            isPublic: true,
            presentationId: null,
            value: null,
            maintainPublicSearch: true,
            canUpdateSavedSearch: true
        };
        c.ngOnInit();
        expect(c.form).toBeDefined();
        expect(c.canUpdateSavedSearch).toEqual(true);
        expect(c.maintainPublicSearch).toEqual(true);
        expect(c.form.controls.value.value).toEqual('search');
    });

    it('should set the the modal from getEntry method', () => {
        c.entry = {};
        c.form = new FormGroup({
          value: new FormControl('Acceptance deadline', [Validators.required]),
          description: new FormControl('Acceptance deadline'),
          isPublic: new FormControl(false)
        });
        c.getEntry();
        expect(c.entry.value).toEqual('Acceptance deadline');
      });
});