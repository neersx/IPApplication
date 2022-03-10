import { ChangeDetectorRefMock } from 'mocks';
import { CaseWebLinksComponent } from './caseweblinks.component';

describe('CaseWebLinksComponent', () => {
    let component: CaseWebLinksComponent;
    let changeDetectorRefMock: ChangeDetectorRefMock;

    beforeEach(() => {
        changeDetectorRefMock = new ChangeDetectorRefMock();
        component = new CaseWebLinksComponent(changeDetectorRefMock as any);
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('validate hasCaseLinks method', () => {
        const result = component.hasCaseLinks();
        expect(result).toBeFalsy();
    });

    it('validate hasCaseLinks method', () => {
        const item: any = null;
        const index = 1;
        const result = component.trackByFn(index, item);
        expect(result).toBe(index);
    });
});
