import { FormControl, NgForm } from '@angular/forms';
import { ChangeDetectorRefMock, RoleSearchMock } from 'mocks';
import { RolesOverviewComponent } from './roles-overview.component';

describe('RolesOverviewComponent', () => {
    let c: RolesOverviewComponent;
    const service = new RoleSearchMock();
    const cdr = new ChangeDetectorRefMock();
    let viewData: any;
    beforeEach(() => {
        c = new RolesOverviewComponent(cdr as any, service as any);
        viewData = {
            roleId: 1
        };
        c.topic = {
            params: {
                viewData
            },
            key: 'Status',
            title: 'Status'
        };
        c.formData = new NgForm(null, null);
        c.formData.form.addControl('belongingTo', new FormControl(null, null));
        c.overViewForm = c.formData;
    });
    it('should initialize RolesOverviewComponent', () => {
        expect(c).toBeTruthy();
    });
    it('should call ngOnInit ', () => {
        c.ngOnInit();
        expect(service.overviewDetails).toHaveBeenCalled();
    });
    it('should call revert ', () => {
        c.revert();
        expect(c.formData).toEqual({});
    });
    it('should call getFormData ', () => {
        const formValue = c.getFormData();
        expect(formValue.formData.overviewDetails).toBeTruthy();
    });
});