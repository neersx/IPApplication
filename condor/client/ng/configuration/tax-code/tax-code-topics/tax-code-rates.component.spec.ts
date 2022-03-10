import { FormBuilder, FormGroup } from '@angular/forms';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock, DateHelperMock, EventEmitterMock, IpxGridOptionsMock } from 'mocks';
import { TaxCodeMock } from 'mocks/tax-code.mock';
import { TaxCodeRatesComponent } from './tax-code-rates.component';

describe('TaxCodeRatesComponent', () => {
    let component: TaxCodeRatesComponent;
    const localSettings = new LocalSettingsMock();
    const service = new TaxCodeMock();
    const cdr = new ChangeDetectorRefMock();
    const dateHelper = new DateHelperMock();
    let viewData: any;
    beforeEach(() => {
        component = new TaxCodeRatesComponent(service as any, localSettings as any, new FormBuilder(), cdr as any, dateHelper as any);
        component.gridOptions = new IpxGridOptionsMock() as any;
        viewData = {
            taskSecurity: {
                canCreateTaxCode: true,
                canUpdateTaxCode: true,
                canDeleteTaxCode: true
            },
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
        component.grid = {
            checkChanges: jest.fn(),
            wrapper: {
                data: [
                    {
                        sourceJurisdiction: 'Afghanistan',
                        taxRate: 10,
                        effectiveDate: new Date('28-Feb-2022'),
                        id: 2,
                        status: 'D'
                    }, {
                        sourceJurisdiction: null,
                        taxRate: 10,
                        effectiveDate: new Date('28-Feb-2022'),
                        id: 1,
                        status: 'A'
                    }
                ]
            }
        } as any;
    });
    it('should initialize TaxCodeRatesComponent', () => {
        expect(component).toBeTruthy();
    });
    it('should call ngOnInit', () => {
        component.ngOnInit();
        expect(component.viewData).toEqual(viewData);
        expect(component.sourceJurisdiction).toEqual(false);
        expect(component.gridOptions.columns.length).toEqual(3);
    });
    it('should call revert', () => {
        component.revert();
        expect(component.isGridDirty).toEqual(false);
        expect(component.isGridValid).toEqual(false);
    });
    it('should call isDirty', () => {
        component.isDirty();
        expect(component.isGridDirty).toEqual(false);
    });
    it('should call getDataRows', () => {
        const result = component.getDataRows();
        expect(result.length).toEqual(2);
    });
    it('should update status correctly ', () => {
        (component.topic.setCount as any) = new EventEmitterMock<number>();
        component.updateChangeStatus();
        expect(component.grid.checkChanges).toHaveBeenCalled();
        expect(component.isGridDirty).toEqual(true);
    });
    it('should call change', () => {
        (component.topic.setCount as any) = new EventEmitterMock<number>();
        component.change({
            id: 2
        });
        expect(component.isGridValid).toEqual(true);
    });
    it('should call createFromGroup', () => {
        const dataItem = { taxRateId: 1, sourceJurisdiction: 'Afghanistan', taxRate: 10, effectiveDate: '03-Mar-2022', status: 'A' };
        const group = component.createFormGroup(dataItem);
        expect(group).toEqual(expect.any(FormGroup));
        expect(component.gridOptions.formGroup).toBeDefined();
        expect(Object.keys(group.controls)).toEqual(['taxRateId', 'sourceJurisdiction', 'taxRate', 'effectiveDate']);
    });
});