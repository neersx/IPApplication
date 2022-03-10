namespace inprotech.portfolio.cases {
    describe('inprotech.portfolio.cases.displayableFields', function () {
        'use strict';

        let helper: DisplayableNameTypeFieldsHelper;
        beforeEach(function () {
            helper = new DisplayableNameTypeFieldsHelper();
        });

        describe('should intepret flag correctly', () => {
            it('should check and return address', () => {
                let r = helper.shouldDisplay(NameTypeFieldFlags.address, [helper.mapFlag('address')]);
                expect(r).toEqual(true);
            });
            it('should check and return assign date', () => {
                let r = helper.shouldDisplay(NameTypeFieldFlags.assignDate, [helper.mapFlag('assignDate')]);
                expect(r).toEqual(true);
            });
            it('should check and return date commenced / start date', () => {
                let r = helper.shouldDisplay(NameTypeFieldFlags.dateCommenced, [helper.mapFlag('dateCommenced')]);
                expect(r).toEqual(true);
            });
            it('should check and return date ceased / expiry date', () => {
                let r = helper.shouldDisplay(NameTypeFieldFlags.dateCeased, [helper.mapFlag('dateCeased')]);
                expect(r).toEqual(true);
            });
            it('should check and return bill Percentage', () => {
                let r = helper.shouldDisplay(NameTypeFieldFlags.billPercentage, [helper.mapFlag('billPercentage')]);
                expect(r).toEqual(true);
            });
            it('should check and return inherited flag', () => {
                let r = helper.shouldDisplay(NameTypeFieldFlags.inherited, [helper.mapFlag('inherited')]);
                expect(r).toEqual(true);
            });
            it('should check and return remarks / comments', () => {
                let r = helper.shouldDisplay(NameTypeFieldFlags.remarks, [helper.mapFlag('remarks')]);
                expect(r).toEqual(true);
            });
            it('should check and return nationality', () => {
                let r = helper.shouldDisplay(NameTypeFieldFlags.nationality, [helper.mapFlag('nationality')]);
                expect(r).toEqual(true);
            });
            it('should check and return telecom', () => {
                let r = helper.shouldDisplay(NameTypeFieldFlags.telecom, [helper.mapFlag('telecom')]);
                expect(r).toEqual(true);
            });
        });

        describe('should intepret multiple flags correctly', () => {
            it('should check and return address, assign date & nationality', () => {
                // tslint:disable:no-bitwise
                let required = NameTypeFieldFlags.address | NameTypeFieldFlags.assignDate | NameTypeFieldFlags.nationality;
                // tslint:enable:no-bitwise
                let r1 = helper.shouldDisplay(required, [NameTypeFieldFlags.address, NameTypeFieldFlags.assignDate, NameTypeFieldFlags.nationality]);
                expect(r1).toEqual(true);

                let r2 = helper.shouldDisplay(required, [NameTypeFieldFlags.assignDate]);
                expect(r2).toEqual(true);

                let r3 = helper.shouldDisplay(required, [NameTypeFieldFlags.address]);
                expect(r3).toEqual(true);

                let r4 = helper.shouldDisplay(required, [NameTypeFieldFlags.remarks]);
                expect(r4).toEqual(false);

                let r5 = helper.shouldDisplay(required, [NameTypeFieldFlags.nationality]);
                expect(r5).toEqual(true);
            });
        });
    });
}