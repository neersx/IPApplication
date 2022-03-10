 describe('ipWorkflowsEventControlChargeForm', function() {
     'use strict';

     var controller;
     beforeEach(function() {
         module('inprotech.configuration.rules.workflows');
         inject(function($componentController) {
             controller = function(charge, form, canEdit) {
                 var c = $componentController('ipWorkflowsEventControlChargeForm', {}, {
                     canEdit: canEdit != null ? canEdit : true,
                     form: _.extend({}, form),
                     charge: _.extend({}, charge)
                 });
                 c.$onInit();
                 return c;
             }
         });
     });

     describe('initialise', function() {
         it('calls onChargeTypeChanged onload', function() {
             var c = controller();
             spyOn(c, 'onChargeTypeChanged');

             c.onload();

             expect(c.onChargeTypeChanged).toHaveBeenCalledWith();
         });
     });


     describe('checkboxes disable functions', function() {
         var ctrl, charge;
         beforeEach(function() {
             charge = {
                 chargeType: {
                     key: 1
                 }
             }
             ctrl = controller(charge);
         });

         it('return true if canEdit is false', function() {
             ctrl.canEdit = false;
             expect(ctrl.isCheckboxDisabled()).toBe(true);
             expect(ctrl.isDirectPayDisabled()).toBe(true);
         });

         it('return true if charge type is empty', function() {
             ctrl.charge.chargeType.key = null;
             expect(ctrl.isCheckboxDisabled()).toBe(true);
             expect(ctrl.isDirectPayDisabled()).toBe(true);
         });

         it('return true for other checkboxes if direct pay is checked', function() {
             ctrl.charge.isDirectPay = true;
             expect(ctrl.isCheckboxDisabled()).toBe(true);
             expect(ctrl.isDirectPayDisabled()).toBe(false);
         });

         it('returns false when canEdit, has charge type and not direct pay', function() {
             expect(ctrl.isCheckboxDisabled()).toBe(false);
             expect(ctrl.isDirectPayDisabled()).toBe(false);
         });
     });

     describe('onChargeTypeChanged', function() {
         it('should update vm and disable all checkboxes when raise charge is empty', function() {
             var ctrl = controller({
                 isPayFee: true,
                 isRaiseCharge: true,
                 isEstimate: true,
                 isDirectPay: true
             });

             ctrl.onChargeTypeChanged();

             var charge = ctrl.charge;
             expect(charge.isPayFee).toEqual(false);
             expect(charge.isRaiseCharge).toEqual(false);
             expect(charge.isEstimate).toEqual(false);
             expect(charge.isDirectPay).toEqual(false);
         });

         it('should check raised charge and enable all checkboxes when raise charge is not empty and all checkboxes are unchecked', function() {
             var ctrl = controller({
                 chargeType: {
                     key: 'raiseCharge'
                 },
                 isPayFee: false,
                 isRaiseCharge: false,
                 isEstimate: false,
                 isDirectPay: false
             });

             ctrl.onChargeTypeChanged();

             expect(ctrl.charge.isRaiseCharge).toEqual(true);
         });
     });

     describe('checkbox onChange', function() {
         var ctrl;
         beforeEach(function() {
             ctrl = controller();
             spyOn(ctrl, 'keepCheckedIfOnlyOneChecked');
             spyOn(ctrl, 'uncheckMutuallyExclusive');
         });

         describe('onPayFeeChanged', function() {
             it('validates checkboxes', function() {
                 ctrl.onPayFeeChanged();

                 expect(ctrl.keepCheckedIfOnlyOneChecked).toHaveBeenCalledWith('isPayFee');
                 expect(ctrl.uncheckMutuallyExclusive).toHaveBeenCalledWith('isPayFee');
             });
         });
         describe('onRaiseChargeChanged', function() {
             it('validates checkboxes', function() {
                 ctrl.onRaiseChargeChanged();

                 expect(ctrl.keepCheckedIfOnlyOneChecked).toHaveBeenCalledWith('isRaiseCharge');
                 expect(ctrl.uncheckMutuallyExclusive).toHaveBeenCalledWith('isPayFee');
             });
         });
         describe('onEstimateChanged', function() {
             it('validates checkboxes', function() {
                 ctrl.onEstimateChanged();

                 expect(ctrl.keepCheckedIfOnlyOneChecked).toHaveBeenCalledWith('isEstimate');
                 expect(ctrl.uncheckMutuallyExclusive).toHaveBeenCalledWith('isEstimate');
             });
         });

         describe('onDirectPayChange', function() {
             it('turns off other checkboxes', function() {
                 ctrl.charge.isDirectPay = true;
                 ctrl.onDirectPayChange();

                 expect(ctrl.charge.isPayFee).toEqual(false);
                 expect(ctrl.charge.isRaiseCharge).toEqual(false);
                 expect(ctrl.charge.isEstimate).toEqual(false);

                 ctrl.charge.isDirectPay = false;

                 ctrl.onDirectPayChange();
                 expect(ctrl.charge.isRaiseCharge).toEqual(true);
             });
         });
     });

     describe('checkbox validation logic', function() {
         var ctrl;
         beforeEach(function() {
             ctrl = controller();
         });

         describe('keepCheckedIfOnlyOneChecked', function() {
             it('the clicked checkbox should be true when no other checkboxes is checked', function() {
                 ctrl.charge.isRaiseCharge = false;
                 ctrl.charge.isEstimate = false;
                 ctrl.charge.isDirectPay = false;
                 ctrl.charge.isPayFee = false;

                 ctrl.keepCheckedIfOnlyOneChecked('isEstimate');

                 expect(ctrl.charge.isRaiseCharge).toEqual(false);
                 expect(ctrl.charge.isEstimate).toEqual(true);
                 expect(ctrl.charge.isDirectPay).toEqual(false);
                 expect(ctrl.charge.isPayFee).toEqual(false);
             });

             it('the clicked checkbox should not change key when at least one other checkboxes is checked', function() {
                 ctrl.charge.isRaiseCharge = true;
                 ctrl.charge.isEstimate = false;
                 ctrl.charge.isDirectPay = false;
                 ctrl.charge.isPayFee = false;

                 ctrl.keepCheckedIfOnlyOneChecked('isEstimate');

                 expect(ctrl.charge.isRaiseCharge).toEqual(true);
                 expect(ctrl.charge.isEstimate).toEqual(false);
                 expect(ctrl.charge.isDirectPay).toEqual(false);
                 expect(ctrl.charge.isPayFee).toEqual(false);
             });
         });

         describe('uncheckMutuallyExclusive', function() {
             it('should set another checkbox unckecked when isRaiseCharge unckecked', function() {
                 ctrl.charge.isPayFee = true;
                 ctrl.charge.isEstimate = true;
                 ctrl.charge.isRaiseCharge = false;

                 ctrl.uncheckMutuallyExclusive('isPayFee');

                 expect(ctrl.charge.isEstimate).toEqual(false);
             });

             it('should not set another checkbox unckecked when isRaiseCharge checked', function() {
                 ctrl.charge.isPayFee = true;
                 ctrl.charge.isEstimate = true;
                 ctrl.charge.isRaiseCharge = true;

                 ctrl.uncheckMutuallyExclusive('isPayFee');

                 expect(ctrl.charge.isEstimate).toEqual(true);
             });
         });
     });
 });