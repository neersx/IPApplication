describe('inprotech.configuration.general.validcombination.CopyValidCombinationController', function() {
    'use strict';

    var controller;

    beforeEach(function() {
        module('inprotech.configuration.general.validcombination');
    });

    beforeEach(inject(function($controller) {
        controller = function() {
            var c = $controller('CopyValidCombinationController', {}, {
                copyEntity: {}
            });
            c.$onInit();
            return c;
        };
    }));
    describe('initialise', function() {
        it('all the characteristics should be selected', function() {
            var c = controller();

            expect(c.copyEntity.selectAll).toBe(true);
            expect(c.copyEntity.action).toBe(true);
            expect(c.copyEntity.basis).toBe(true);
            expect(c.copyEntity.category).toBe(true);
            expect(c.copyEntity.checklist).toBe(true);
            expect(c.copyEntity.propertyType).toBe(true);
            expect(c.copyEntity.relationship).toBe(true);
            expect(c.copyEntity.subType).toBe(true);
            expect(c.copyEntity.status).toBe(true);
        });
    });
    describe('select all change', function() {
        it('should set all the characteristics false if select all is unchecked', function() {
            var c = controller();

            c.copyEntity.selectAll = false;
            c.selectAll();

            expect(c.copyEntity.action).toBe(false);
            expect(c.copyEntity.basis).toBe(false);
            expect(c.copyEntity.category).toBe(false);
            expect(c.copyEntity.checklist).toBe(false);
            expect(c.copyEntity.propertyType).toBe(false);
            expect(c.copyEntity.relationship).toBe(false);
            expect(c.copyEntity.subType).toBe(false);
            expect(c.copyEntity.status).toBe(false);
        });
        it('should set all the characteristics true if select all is checked', function() {
            var c = controller();

            c.copyEntity.selectAll = true;
            c.selectAll();

            expect(c.copyEntity.action).toBe(true);
            expect(c.copyEntity.basis).toBe(true);
            expect(c.copyEntity.category).toBe(true);
            expect(c.copyEntity.checklist).toBe(true);
            expect(c.copyEntity.propertyType).toBe(true);
            expect(c.copyEntity.relationship).toBe(true);
            expect(c.copyEntity.subType).toBe(true);
            expect(c.copyEntity.status).toBe(true);
        });
    });
    describe('any characteristic change', function() {
        it('should set selectAll as false', function() {
            var c = controller();

            c.selectAnyCharacteristic(false);

            expect(c.copyEntity.selectAll).toBe(false);
        });
    });
    describe('hasSameValue', function() {
        it('is true if to jurisdictions contain from jurisdiction value', function() {
            var c = controller();
            c.copyEntity.fromJurisdiction = {
                key: 'AU',
                code: 'AU',
                value: 'Australia'
            };
            c.copyEntity.toJurisdictions = [{
                key: 'US',
                value: 'United States of America'
            }, {
                key: 'AU',
                value: 'Australia'
            }];

            expect(c.copyEntity.hasSameValue()).toBe(true);
        });
        it('is false if to jurisdictions doesnot contain from jurisdiction value', function() {
            var c = controller();
            c.copyEntity.fromJurisdiction = {
                key: 'AU',
                code: 'AU',
                value: 'Australia'
            };
            c.copyEntity.toJurisdictions = [{
                key: 'US',
                value: 'United States of America'
            }];

            expect(c.copyEntity.hasSameValue()).toBe(false);

            c.copyEntity.toJurisdictions = null;
            expect(c.copyEntity.hasSameValue()).toBe(false);
        });
    });
    describe('enableCopySave', function() {
        it('should return false if jurisdictions form is touched and is invalid', function() {
            var c = controller();
            c.jurisdictions = {
                $dirty: true,
                $valid: false
            };

            expect(c.enableCopySave()).toBe(false);
        });
        it('should return true if jurisdictions form is touched and is valid', function() {
            var c = controller();
            c.jurisdictions = {
                $valid: true,
                $dirty: true
            };

            expect(c.enableCopySave()).toBe(true);
        });
    });
});