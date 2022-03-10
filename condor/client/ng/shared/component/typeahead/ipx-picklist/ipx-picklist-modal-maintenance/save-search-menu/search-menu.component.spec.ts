import { async } from '@angular/core/testing';
import { HttpClientMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import * as _ from 'underscore';
import { IpxPicklistMaintenanceService } from '../../ipx-picklist-maintenance.service';
import { IpxPicklistSaveSearchMenuComponent } from './search-menu.component';

describe('CaseSearchComponent', () => {
    let c: IpxPicklistSaveSearchMenuComponent;
    const httpMock = new HttpClientMock();
    const notificationServiceMock = new NotificationServiceMock();
    let picklistMaintenanceServiceMock;
    const translateServiceMock = new TranslateServiceMock();

    beforeEach(() => {
        picklistMaintenanceServiceMock = new IpxPicklistMaintenanceService(httpMock as any, notificationServiceMock as any, translateServiceMock as any);
        c = new IpxPicklistSaveSearchMenuComponent(picklistMaintenanceServiceMock);
        c.entry = {
            key: '1',
            value: 'Test Value',
            groupName: 'Test Value',
            contextID: 2
        };
    });

    it('should create the component', async(() => {
        expect(c).toBeTruthy();
    }));

    it('should initialize component properties', async(() => {
        spyOn(c, 'loadSearchGroupData');
        c.ngOnInit();
        expect(c.isUpdateAccess).toBe(false);
        expect(c.loadSearchGroupData).toBeCalled();
    }));

    it('should set form control values', async(() => {
        c.ngOnInit();
        expect(c.form.controls.value.value).toBe(c.entry.value);
    }));

});
