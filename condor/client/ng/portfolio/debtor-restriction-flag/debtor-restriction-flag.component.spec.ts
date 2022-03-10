import { of } from 'rxjs';
import { DebtorRestrictionFlagComponent } from './debtor-restriction-flag.component';
describe('DebtorRestrictionFlagComponent', () => {
    let restrictionServiceMock: any;
    let component: DebtorRestrictionFlagComponent;
    beforeEach(() => {
        restrictionServiceMock = {
            getRestrictions: jest.fn().mockReturnValue(of([]))
        };
        component = new DebtorRestrictionFlagComponent(restrictionServiceMock);
    });

    it('should be created', () => {
        expect(component).toBeTruthy();
    });

    describe('load', () => {
        it('should not load debtor if no debtorId', () => {
            component.debtor = null;

            component.load();

            expect(restrictionServiceMock.getRestrictions).not.toHaveBeenCalled();
            expect(component.description).toEqual('');
            expect(component.severity).toEqual('');
        });

        it('should load debtor if debtorId', () => {
            component.debtor = 1;

            component.load();

            expect(restrictionServiceMock.getRestrictions).toHaveBeenCalledWith(1);
        });

        it('should set severity and description if there is a record', () => {
            const mockRestriction = {
                severity: 'mockSeverity',
                description: 'mockDescription'
            };
            restrictionServiceMock.getRestrictions.mockReturnValue(of([mockRestriction]));
            component.debtor = 1;

            component.load();

            expect(component.description).toEqual(mockRestriction.description);
            expect(component.severity).toEqual(mockRestriction.severity);
        });

        it('should set severity and description to empty if there is no record', () => {
            restrictionServiceMock.getRestrictions.mockReturnValue(of([]));
            component.debtor = 1;

            component.load();

            expect(component.description).toEqual('');
            expect(component.severity).toEqual('');
        });
    });
});