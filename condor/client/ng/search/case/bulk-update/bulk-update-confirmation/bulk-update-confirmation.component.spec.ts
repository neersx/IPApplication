
import { NgForm } from '@angular/forms';
import { CommonUtilityServiceMock } from 'core/common.utility.service.mock';
import { BsModalRefMock, ChangeDetectorRefMock, TranslateServiceMock } from 'mocks';
import { Subject } from 'rxjs';
import { BulkUpdateReasonData } from '../bulk-update.data';
import { BulkUpdateServiceMock } from '../bulk-update.service.mock';
import { BulkUpdateConfirmationComponent } from './bulk-update-confirmation.component';

describe('BulkUpdateConfirmationComponent', () => {
    let component: BulkUpdateConfirmationComponent;
    const bsModalRefMock = new BsModalRefMock();
    const translateMock = new TranslateServiceMock();
    const commonServiceMock = new CommonUtilityServiceMock();
    const bulkUpdateService = new BulkUpdateServiceMock();
    const changeDetectorRef = new ChangeDetectorRefMock();
    beforeEach(() => {
        component = new BulkUpdateConfirmationComponent(bsModalRefMock as any, translateMock as any, bulkUpdateService as any, changeDetectorRef as any, commonServiceMock as any);
        component.reasonData = new BulkUpdateReasonData();
        component.ngForm = new NgForm(null, null);
    });

    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('validate ngOnInit', () => {
        component.formData = {
            profitCentre: {
                key: 'MYC',
                labelTranslationKey: 'bulkUpdate.fieldUpdate',
                value: 'MYC Partnership'
            },
            caseOffice: {
                key: '',
                labelTranslationKey: 'bulkUpdate.fieldUpdate',
                toRemove: true
            },
            purchaseOrder: {
                key: 'purchaseOrder test',
                labelTranslationKey: 'bulkUpdate.fieldUpdate',
                value: 'purchaseOrder test'
            },
            caseText: {
                key: 'text1',
                labelTranslationKey: 'bulkUpdate.caseTextUpdate',
                value: 'case test'
            },
            fileLocation: {
                key: 'fileloctionkey',
                labelTranslationKey: 'bulkUpdate.fileLocation',
                value: 'file test'
            },
            caseStatus: {
                statusCode: '209',
                labelTranslationKey: 'bulkUpdate.caseStatusUpdate',
                value: 'status test'
            }
        };
        component.selectedCaseCount = 2;
        component.ngOnInit();
        expect(component.replaceItemCount).toEqual(3);
        expect(component.removeItemCount).toEqual(1);
        expect(bulkUpdateService.hasRestrictedCasesForStatus).toHaveBeenCalled();

        bulkUpdateService.hasRestrictedCasesForStatus(component.selectedCases, component.formData.caseStatus.statusCode).subscribe((response) => {
            expect(component.hasRestrictedStatus).toBe(response);
        });
    });

    it('validate reasonChange for reason notes and error message for same case text type and reason text', () => {
        component.reasonData.textType = 'reason text';
        component.reasonData.notes = 'reason notes';
        component.formData = { notes: 'test notes', caseText: { textType: 'reason text' } };
        component.hasCaseText = true;
        component.reasonChange();
        expect(component.reasonData.notes).toEqual('reason notes');
    });

    it('validate reasonChange with blank reason data and valid reason text', () => {
        component.reasonData.textType = undefined;
        component.reasonData.notes = 'reason notes';
        component.formData = { notes: 'test notes', caseText: { textType: 'text' } };
        component.reasonChange();
        expect(component.reasonData.notes).toEqual('');
    });

    it('validate close', () => {
        component.onClose = new Subject();
        component.close();
        expect(bsModalRefMock.hide).toHaveBeenCalled();
    });

    it('validate submit with invalid data', () => {
        component.onClose = new Subject();
        component.reasonData = { notes: 'test notes', textType: undefined };
        const result = component.submit();
        expect(result).toBeFalsy();
    });

    it('validate submit with valid data', () => {
        component.onClose = new Subject();
        component.reasonData = { notes: 'test notes', textType: 'AB' };
        const result = component.submit();
        expect(result).toBeTruthy();
        expect(bsModalRefMock.hide).toHaveBeenCalled();
    });

    it('validate asIsOrder', () => {
        const result = component.asIsOrder();
        expect(result).toEqual(1);
    });

    it('validate trackByFn', () => {
        const result = component.trackByFn(5);
        expect(result).toEqual(5);
    });
});