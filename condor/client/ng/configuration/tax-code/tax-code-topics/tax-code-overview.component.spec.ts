import { FormControl, NgForm } from '@angular/forms';
import { ChangeDetectorRefMock } from 'mocks';
import { TaxCodeMock } from 'mocks/tax-code.mock';
import { TaxCodeOverviewComponent } from './tax-code-overview.component';

describe('TaxCodeOverviewComponent', () => {
    let component: TaxCodeOverviewComponent;
    let cdr: ChangeDetectorRefMock;
    const service = new TaxCodeMock();
    let viewData: any;
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        component = new TaxCodeOverviewComponent(cdr as any, service as any);
        viewData = {
            canAdd: true,
            canUpdate: true,
            canDelete: true,
            taxRateId: 1
        };
        component.topic = {
            key: 'Status',
            title: 'Status',
            params: { viewData }
        };
        component.formData = new NgForm(null, null);
        component.formData.form.addControl('taxCode', new FormControl(null, null));
        component.overViewForm = component.formData;
    });
    it('should initialize TaxCodeOverviewComponent', () => {
        expect(component).toBeTruthy();
    });
    it('should Call ngOnInit', () => {
        component.ngOnInit();
        expect(component.viewData).toEqual(viewData);
        expect(service.overviewDetails).toHaveBeenCalled();
    });

    it('should call revert', () => {
        component.formData = { taxCode: 1 };
        component.revert();
        expect(component.formData).toEqual({});
    });

    it('should call initTopicsData', () => {
        component.ngOnInit();
        component.initTopicsData();
        expect(service.overviewDetails).toHaveBeenCalled();
    });
});