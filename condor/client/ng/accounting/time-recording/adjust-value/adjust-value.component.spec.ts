import { JSDocCommentStmt } from '@angular/compiler';
import { ChangeDetectorRefMock } from 'mocks';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { of } from 'rxjs';
import { AdjustValueComponent } from './adjust-value.component';

describe('Change Entry Date Component', () => {

    let c: AdjustValueComponent;
    let modalRef: BsModalRef;
    let adjustValueService: any;
    let cdRef: ChangeDetectorRefMock;

    beforeEach(() => {
        modalRef = new BsModalRef();
        modalRef.hide = jest.fn();
        adjustValueService = { saveAdjustedValues: jest.fn().mockReturnValue(of({ entryNo: 1234})),
        previewCost: jest.fn().mockReturnValue(of({})) };
        cdRef = new ChangeDetectorRefMock();
        c = new AdjustValueComponent(modalRef, adjustValueService, cdRef as any);
    });
    it('should create', () => {
        expect(c).toBeTruthy();
    });
    describe('Changing local amount', () => {
        beforeEach(() => {
            c.viewItem = { entryNo: 1234 };
            c.item = {
                localValue: 999.99,
                caseKey: -987
            };
            c.staffNameId = -5552368;
            c.ngOnInit();
        });
        it('should call the costing service', () => {
            c.originalLocalValue = 999.99;
            adjustValueService.previewCost = jest.fn().mockReturnValue(of({ localValue: 987.65, exchangeRate: 1.2345 }));
            c.localAmountChanged(987.65);
            expect(adjustValueService.previewCost).toHaveBeenCalledWith(
                expect.objectContaining({ localValueBeforeMargin: 987.65, staffKey: -5552368 })
            );
            expect(c.viewItem.exchangeRate).toBe(1.2345);
            expect(c.canSave).toBe(true);
        });
        it('should only allow saving when local values are different', () => {
            adjustValueService.previewCost = jest.fn().mockReturnValue(of({localValue: 999.99}));
            c.localAmountChanged(987.65);
            expect(c.canSave).toBeFalsy();
        });
        it('should not allow saving if setting to null', () => {
            c.originalLocalValue = 999.99;
            adjustValueService.previewCost = jest.fn().mockReturnValue(of({ localValue: 999.99 }));
            c.localAmountChanged(null);
            expect(c.canSave).toBeFalsy();
            expect(adjustValueService.previewCost).not.toHaveBeenCalled();
        });
        it('should call the costing service if setting to zero', () => {
            c.originalLocalValue = 999.99;
            adjustValueService.previewCost = jest.fn().mockReturnValue(of({ localValue: 0 }));
            c.localAmountChanged(0);
            expect(c.canSave).toBeTruthy();
            expect(adjustValueService.previewCost).toHaveBeenCalledWith(
                expect.objectContaining({ localValueBeforeMargin: 0, staffKey: -5552368 })
            );
        });
    });
    describe('Changing foreign amount', () => {
        beforeEach(() => {
            c.viewItem = { entryNo: 5678 };
            c.item = {
                foreignValue: 999.95,
                caseKey: -987
            };
            c.staffNameId = -5552368;
            c.ngOnInit();
        });
        it('should call the costing service', () => {
            c.originalForeignValue = 999.95;
            adjustValueService.previewCost = jest.fn().mockReturnValue(of({ foreignValue: 987.65, exchangeRate: 1.2345 }));
            c.foreignAmountChanged(987.65);
            expect(adjustValueService.previewCost).toHaveBeenCalledWith(
                expect.objectContaining({ foreignValueBeforeMargin: 987.65, staffKey: -5552368 })
            );
            expect(c.viewItem.exchangeRate).toBe(1.2345);
        });
        it('should only allow saving when foreign values are different', () => {
            adjustValueService.previewCost = jest.fn().mockReturnValue(of({ foreignValue: 999.95 }));
            c.foreignAmountChanged(987.65);
            expect(c.canSave).toBeFalsy();
        });
        it('should not allow saving if setting to null', () => {
            c.originalForeignValue = 999.99;
            adjustValueService.previewCost = jest.fn().mockReturnValue(of({ foreignValue: 999.99 }));
            c.foreignAmountChanged(null);
            expect(c.canSave).toBeFalsy();
            expect(adjustValueService.previewCost).not.toHaveBeenCalled();
        });
        it('should call the costing service if setting to zero', () => {
            c.originalForeignValue = 999.99;
            adjustValueService.previewCost = jest.fn().mockReturnValue(of({ foreignValue: 0 }));
            c.foreignAmountChanged(0);
            expect(c.canSave).toBeTruthy();
            expect(adjustValueService.previewCost).toHaveBeenCalledWith(
                expect.objectContaining({ foreignValueBeforeMargin: 0, staffKey: -5552368 })
            );
        });
    });
    describe('Saving values', () => {
        it('should not call service if it cannot be saved', () => {
            c.canSave = false;
            c.saveValues();
            expect(adjustValueService.saveAdjustedValues).not.toHaveBeenCalled();
            expect(modalRef.hide).not.toHaveBeenCalled();
        });
        it('should call the service with request data and emit the updated entry number', () => {
            c.canSave = true;
            c.viewItem = { entryNo: 1234};
            c.saveValues();
            expect(adjustValueService.saveAdjustedValues).toHaveBeenCalledWith(c.viewItem);
            adjustValueService.saveAdjustedValues()
                .subscribe(() => {
                    expect(c.refreshGrid.emit).toHaveBeenCalledWith(1234);
                    expect(modalRef.hide).toHaveBeenCalled();
                });
        });
    });
    describe('Cancelling', () => {
        it('should hide the modal', () => {
            c.cancelDialog();
            expect(modalRef.hide).toHaveBeenCalledTimes(1);
        });
    });
});