import { ChangeDetectorRefMock, HttpClientMock, IpxNotificationServiceMock } from 'mocks';
import { Observable, of } from 'rxjs';
import { ItemDateValidator } from './item-date-validator';
import { TimeRecordingServiceMock } from './time-recording/time-recording.mock';

describe('ItemDateValidator', () => {
    let http: HttpClientMock;
    let service: ItemDateValidator;
    let timeService: TimeRecordingServiceMock;
    let ipxNotificationService: IpxNotificationServiceMock;
    let cdr: ChangeDetectorRefMock;
    let formGroup: any;

    const datePipe = {
        transform: jest.fn().mockReturnValue(new Date())
    };

    beforeEach(() => {
        http = new HttpClientMock();
        timeService = new TimeRecordingServiceMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        cdr = new ChangeDetectorRefMock();
        service = new ItemDateValidator(http as any, timeService as any, datePipe as any, ipxNotificationService as any, cdr as any);
        formGroup = {
            markAsDirty: jest.fn(),
            patchValue: jest.fn(),
            markAsPristine: jest.fn(),
            controls: {
                itemDate: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    setErrors: jest.fn(),
                    setValue: jest.fn(),
                    value: 100,
                    valueChanges: new Observable<any>()
                }
            }
        };
    });

    it('should be created', () => {
        expect(service).toBeTruthy();
    });

    describe('Billing Services', () => {
        it('calls api to validate date', () => {
            http.get = jest.fn().mockReturnValue(of({}));
            const date = new Date();
            service.validateItemDate$(date, 'billing');
            expect(http.get).toHaveBeenCalledWith('api/accounting/billing/validate', {
                params: {
                    itemDate: date.toString()
                }
            });
        });

        it('should return error when transaction Date is not valid', done => {
            const responseData = {
                HasError: true,
                ValidationErrorList: [{
                    ErrorCode: 'AC124'
                }]
            };

            jest.spyOn(service, 'validateItemDate$').mockReturnValue(of(responseData));
            const date = new Date();
            service.validateItemDate(date, 'billing', formGroup.controls.itemDate);
            service.validateItemDate$(date, 'billing').subscribe(res => {
                expect(res).toBeDefined();
                expect(res.HasError).toBeTruthy();
                expect(res.ValidationErrorList).toBeDefined();
                done();
            });
        });
        it('should return confirmation when transaction Date has warning', done => {
            const responseData = {
                HasError: true,
                ValidationErrorList: [{
                    WarningCode: 'AC128'
                }]
            };

            jest.spyOn(service, 'validateItemDate$').mockReturnValue(of(responseData));
            const date = new Date();
            service.validateItemDate(date, 'billing', formGroup.controls.itemDate);
            service.validateItemDate$(date, 'billing').subscribe(res => {
                expect(res).toBeDefined();
                expect(res.HasError).toBeTruthy();
                expect(res.ValidationErrorList).toBeDefined();
                expect(ipxNotificationService.openConfirmationModal).toBeCalledWith('Warning', 'field.errors.ac128', 'Proceed', 'Cancel');
                done();
            });
        });
        it('should return confirmation when transaction Date has warning', done => {
            const responseData = {
                HasError: true,
                ValidationErrorList: [{
                    WarningCode: 'AC124'
                }]
            };

            jest.spyOn(service, 'validateItemDate$').mockReturnValue(of(responseData));
            const date = new Date();
            service.validateItemDate(date, 'billing', formGroup.controls.itemDate);
            service.validateItemDate$(date, 'billing').subscribe(res => {
                expect(res).toBeDefined();
                expect(res.HasError).toBeTruthy();
                expect(res.ValidationErrorList).toBeDefined();
                expect(ipxNotificationService.openInfoModal).toBeCalledWith('accounting.billing.warning', 'accounting.errors.AC124');
                done();
            });
        });
    });
});
