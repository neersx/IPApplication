import { BsModalRefMock } from 'mocks';
import { DebtorSplit } from '../time-recording-model';
import { DebtorSplitsComponent } from './debtor-splits.component';

describe('DebtorSplitsComponent', () => {
    let c: DebtorSplitsComponent;
    let bsModalRef: any;

    beforeEach(() => {
        bsModalRef = new BsModalRefMock();
        c = new DebtorSplitsComponent(bsModalRef);
    });
    it('tracks splits by debtor no', () => {
        let result = c.trackDebtorSplitsBy(0, { ...new DebtorSplit(), ...{ entryNo: 123, debtorNameNo: 789 } });
        expect(result).toEqual(789);
        result = c.trackDebtorSplitsBy(1, { ...new DebtorSplit(), ...{ entryNo: 555, debtorNameNo: null } });
        expect(result).toBeNull();
        result = c.trackDebtorSplitsBy(2, { ...new DebtorSplit(), ...{ entryNo: 345, debtorNameNo: 0 } });
        expect(result).toEqual(0);
    });

    describe('closing', () => {
        it('hides the modal', () => {
            c.close();
            expect(c.modalRef.hide).toHaveBeenCalled();
        });
    });
});
