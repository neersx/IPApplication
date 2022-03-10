
import { DisplayableNameTypeFieldsHelper, NameTypeFieldFlags } from './displayable-fields';

describe('DisplayableFields', () => {
    let helper: DisplayableNameTypeFieldsHelper;

    beforeEach(() => {
        helper = new DisplayableNameTypeFieldsHelper();
    });

    describe('should intepret flag correctly', () => {
        it('should intepret flag correctly', () => {
            const r = helper.shouldDisplay(NameTypeFieldFlags.address, [helper.mapFlag('address')]);
            expect(r).toEqual(true);
        });
        it('should check and return assign date', () => {
            const r = helper.shouldDisplay(NameTypeFieldFlags.assignDate, [helper.mapFlag('assignDate')]);
            expect(r).toEqual(true);
        });
        it('should check and return date commenced / start date', () => {
            const r = helper.shouldDisplay(NameTypeFieldFlags.dateCommenced, [helper.mapFlag('dateCommenced')]);
            expect(r).toEqual(true);
        });
        it('should check and return date ceased / expiry date', () => {
            const r = helper.shouldDisplay(NameTypeFieldFlags.dateCeased, [helper.mapFlag('dateCeased')]);
            expect(r).toEqual(true);
        });
        it('should check and return bill Percentage', () => {
            const r = helper.shouldDisplay(NameTypeFieldFlags.billPercentage, [helper.mapFlag('billPercentage')]);
            expect(r).toEqual(true);
        });
        it('should check and return inherited flag', () => {
            const r = helper.shouldDisplay(NameTypeFieldFlags.inherited, [helper.mapFlag('inherited')]);
            expect(r).toEqual(true);
        });
        it('should check and return remarks / comments', () => {
            const r = helper.shouldDisplay(NameTypeFieldFlags.remarks, [helper.mapFlag('remarks')]);
            expect(r).toEqual(true);
        });
        it('should check and return nationality', () => {
            const r = helper.shouldDisplay(NameTypeFieldFlags.nationality, [helper.mapFlag('nationality')]);
            expect(r).toEqual(true);
        });
        it('should check and return telecom', () => {
            const r = helper.shouldDisplay(NameTypeFieldFlags.telecom, [helper.mapFlag('telecom')]);
            expect(r).toEqual(true);
        });
    });

    describe('should intepret multiple flags correctly', () => {
        it('should check and return address, assign date & nationality', () => {
            // tslint:disable-next-line:no-bitwise
            const required = NameTypeFieldFlags.address | NameTypeFieldFlags.assignDate | NameTypeFieldFlags.nationality;
            // tslint:enable:no-bitwise
            const r1 = helper.shouldDisplay(required, [NameTypeFieldFlags.address, NameTypeFieldFlags.assignDate, NameTypeFieldFlags.nationality]);
            expect(r1).toEqual(true);

            const r2 = helper.shouldDisplay(required, [NameTypeFieldFlags.assignDate]);
            expect(r2).toEqual(true);

            const r3 = helper.shouldDisplay(required, [NameTypeFieldFlags.address]);
            expect(r3).toEqual(true);

            const r4 = helper.shouldDisplay(required, [NameTypeFieldFlags.remarks]);
            expect(r4).toEqual(false);

            const r5 = helper.shouldDisplay(required, [NameTypeFieldFlags.nationality]);
            expect(r5).toEqual(true);
        });
    });
});