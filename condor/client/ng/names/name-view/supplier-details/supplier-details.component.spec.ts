import { FormControl, NgForm, Validators } from '@angular/forms';
import { ChangeDetectorRefMock, NotificationServiceMock } from 'mocks';
import { WindowParentMessagingServiceMock } from 'mocks/window-parent-messaging.service.mock';
import { of } from 'rxjs';
import { NameViewService } from '../name-view.service';
import { SupplierDetailsComponent } from './supplier-details.component';

describe('SupplierDetailsComponent', () => {
    let component: SupplierDetailsComponent;
    let service: NameViewService;
    let cdRef = new ChangeDetectorRefMock();
    let nservice: NotificationServiceMock;
    let parentMsg: WindowParentMessagingServiceMock;

    beforeEach(() => {
        service = new NameViewService(null);
        cdRef = new ChangeDetectorRefMock();
        nservice = new NotificationServiceMock();
        parentMsg = new WindowParentMessagingServiceMock();
        service.getSupplierDetails$ = jest.fn().mockReturnValue(of ({
            supplierType: '016969',
            purchaseDescription: 'buy buy buy',
            reasonCode: 'bad reason',
            purchaseCurrency: {code: '', description: ''},
            exchangeRate: null,
            profitCentre: {code: 'aaa', description: 'alphabets'},
            ledgerAcc: {code: 'acc', description: 'account'},
            wipDisbursement: {code: 'abc', description: 'abcd', key: 'abc', value: 'abcd'},
            instruction: 'test instruction',
            withPayee: 'payeeeee',
            paymentMethod: 'method1',
            intoBankAccounts: '11^123^1',
            restrictionKey: 1,
            sentToNameKey: null,
            sendToName: {key: -496, code: '000123', displayName: 'Origami & Beech', remarks: null, ceased: null},
            sendToAttentionName: {key: -495, code: null, displayName: 'Origami, Ken', remarks: null, ceased: null}
        }));
        component = new SupplierDetailsComponent(service, cdRef as any, nservice as any, parentMsg as any);
        component.ngForm = new NgForm(null, null);
        component.ngForm.form.addControl('reasonForRestriction', new FormControl(null, Validators.required));
        component.topic = {
            key: '123',
            title: 'supplier',
            params: {
                viewData: {
                    paymentMethods: [{
                        key: '1',
                        value: 'pm1'
                    }, {
                        key: '2',
                        value: 'pm2'
                    }],
                    intoBankAccounts: [{
                            key: '11^123^1',
                            value: 'val1'
                        },
                        {
                            key: 'T0',
                            value: 'val1'
                        }
                    ],
                    paymentRestrictions: [{
                        key: '1',
                        value: 'val1'
                    },
                    {
                        key: '2',
                        value: 'val1'
                    }],
                    reasonsForRestrictions: [{
                        key: 'reason1',
                        value: 'rs1'
                    },
                    {
                        key: 'reason1',
                        value: 'rs2'
                    }],
                    supplierTypes: [{
                        key: '1',
                        value: 'sup1'
                    }, {
                        key: '2',
                        value: 'sup2'
                    }],
                    taxRates: [{
                        key: '0',
                        value: 'Exempt'
                        }, {
                        key: 'T0',
                        value: 'Zero Rated'
                        }, {
                        key: 'T1',
                        value: 'Standard'
                    }]
                }
            }
        };
    });

    it('should set the reason to blank if restriction is blank', (() => {
        component.formData.reasonCode = 'abc';
        expect(component.formData.reasonCode).toBe('abc');
        expect(component.setReason).toBeDefined();
        component.formData.restrictionKey = '';
        component.setReason();
        expect(component.formData.reasonCode).toBe('');
    }));
    it('should create the component', (() => {
        expect(component).toBeTruthy();
        expect(component.sendToNameExtendQuery).toBeTruthy();
        expect(component.wipTemplateExtendQuery).toBeTruthy();
    }));
    it('should initialise correctly', (() => {
        component.ngOnInit();
        expect(component.supplierTypes[1].value).toBe('sup2');
        expect(component.taxRates[2].value).toBe('Standard');
        expect(component.formData.supplierType).toBe('016969');
        expect(component.formData.purchaseDescription).toBe('buy buy buy');
        expect(component.formData.reasonCode).toBe('bad reason');

        expect(component.formData.purchaseCurrency.code).toBe('');
        expect(component.formData.exchangeRate).toBe(null);
        expect(component.formData.profitCentre.code).toBe('aaa');
        expect(component.formData.ledgerAcc.description).toBe('account');
        expect(component.formData.wipDisbursement.key).toBe('abc');
        expect(component.formData.wipDisbursement.value).toBe('abcd');
        expect(component.paymentMethods[1].value).toBe('pm2');
        expect(component.intoBankAccounts[0].key).toBe('11^123^1');
        expect(component.formData.instruction).toBe('test instruction');
        expect(component.formData.reasonCode).toBe('bad reason');

        expect(component.formData.withPayee).toBe('payeeeee');
        expect(component.formData.paymentMethod).toBe('method1');
        expect(component.formData.intoBankAccounts).toBe('11^123^1');
        expect(component.formData.restrictionKey).toBe(1);
        expect(component.formData.sentToNameKey).toBe(null);
    }));

    it('should clear out attention field when send to is blank', (() => {
        component.ngOnInit();
        expect(component.formData.sendToAttentionName.key).toEqual(-495);
        component.formData.sendToName = null;
        component.toggleAttention();
        expect(component.formData.sendToAttentionName).toBeNull();
    }));

    it('should call checkValidation on required field changed', (() => {
        component.ngOnInit();
        component.formData.reasonCode = '';
        expect(component.formData.reasonCode).toBe('');
        expect(component.setReason).toBeDefined();
        component.formData.restrictionKey = 'aaa';
        component.checkValidationAndEnableSave = jest.fn();
        component.setReason();
        expect(component.checkValidationAndEnableSave).toHaveBeenCalled();
        expect(component.ngForm.form.valid).toBeFalsy();
    }));

    it('should revert fields when the discard button is clicked', (() => {
        component.ngOnInit();
        component.formData.purchaseDescription = 'this is changed';
        component.revert();
        expect(component.formData.purchaseDescription).toBe('buy buy buy');
    }));
});