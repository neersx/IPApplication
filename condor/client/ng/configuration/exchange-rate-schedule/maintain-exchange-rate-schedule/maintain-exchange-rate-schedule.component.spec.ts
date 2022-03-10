import { FormBuilder } from '@angular/forms';
import { BsModalRefMock, ChangeDetectorRefMock, GridNavigationServiceMock, IpxNotificationServiceMock } from 'mocks';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { ExchangeRateScheduleRequest } from '../exchange-rate-schedule.model';
import { MaintainExchangeRateScheduleComponent } from './maintain-exchange-rate-schedule.component';

describe('MaintainExchangeRateScheduleComponent', () => {
    let component: MaintainExchangeRateScheduleComponent;
    let ipxNotificationService: IpxNotificationServiceMock;
    let bsModal: BsModalRefMock;
    const fb = new FormBuilder();
    let cdr: ChangeDetectorRefMock;
    let navService: GridNavigationServiceMock;
    let shortcutsService: IpxShortcutsServiceMock;
    let destroy$: any;

    const service = {
        getExchangeRateScheduleDetails: jest.fn().mockReturnValue(of({})),
        validateExchangeRateScheduleCode: jest.fn().mockReturnValue(of({})),
        submitExchangeRateSchedule: jest.fn().mockReturnValue(of({}))
    };

    beforeEach(() => {
        ipxNotificationService = new IpxNotificationServiceMock();
        bsModal = new BsModalRefMock();
        navService = new GridNavigationServiceMock();
        cdr = new ChangeDetectorRefMock();
        shortcutsService = new IpxShortcutsServiceMock();
        destroy$ = of({}).pipe(delay(1000));
        component = new MaintainExchangeRateScheduleComponent(service as any, cdr as any, ipxNotificationService as any, bsModal as any, fb, navService as any, destroy$, shortcutsService as any, {} as any);
        component.onClose$.next = jest.fn() as any;
        component.form = {
            reset: jest.fn(),
            value: {},
            valid: false,
            dirty: false
        };
        component.navData = {
            keys: [{ value: 1 }],
            totalRows: 3,
            pageSize: 10,
            fetchCallback: jest.fn().mockReturnValue({ keys: [{ value: 1 }, { value: 4 }, { value: 31 }] })
        };
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('should set formData', () => {
        const data: ExchangeRateScheduleRequest = {
            id: 1,
            code: 'AB',
            description: 'Desc'
        };
        component.form = { setValue: jest.fn() };
        component.setFormData(data);
        expect(component.form.setValue).toBeCalledWith(data);
    });

    it('should create new formGroup', () => {
        component.createFormGroup();
        expect(component.form).not.toBeNull();
    });

    it('should submit formData', () => {
        const result = {
            id: 1,
            code: 'AB',
            description: 'Desc'
        };
        component.form = {
            value: result,
            valid: true,
            dirty: true
        };
        component.submit();
        expect(component.form).not.toBeNull();
    });

    it('should discard changes', () => {
        component.form = {
            dirty: true
        };
        component.cancel();
        expect(component.form).not.toBeNull();
        component.sbsModalRef.content.confirmed$.subscribe(() => {
            expect(component.form).not.toBeNull();
        });
    });

    it('should reset form', () => {
        component.resetForm();
        expect(component.onClose$.next).toHaveBeenCalledWith(false);
        expect(bsModal.hide).toHaveBeenCalled();
        expect(component.form.reset).toBeCalled();
    });

    it('should get next exchange rate schedule details', () => {
        component.form = {
            markAsPristine: jest.fn()
        };
        jest.spyOn(component, 'getExchangeRateScheduleDetails');
        component.getExchangeRateScheduleDetails(1);
        expect(component.getExchangeRateScheduleDetails).toBeCalled();
    });

    it('should validate unique exchange rate schedule code', () => {
        component.form = {
            patchValue: jest.fn(),
            markAsPristine: jest.fn(),
            controls: {
                code: {
                    markAsDirty: jest.fn(),
                    patchValue: jest.fn(),
                    value: 'abc'
                }
            }
        };

        component.validateExchangeRateScheduleCode();
        expect(component.form.patchValue).toBeCalledWith({ code: 'abc'.toUpperCase() });
        expect(service.validateExchangeRateScheduleCode).toBeCalled();
    });
});