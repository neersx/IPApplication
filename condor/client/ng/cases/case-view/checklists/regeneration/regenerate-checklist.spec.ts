import { BsModalRefMock } from 'mocks/bs-modal.service.mock';
import * as _ from 'underscore';
import { RegenerateChecklistComponent } from './regenerate-checklist';

describe('RegenerateChecklistComponent Component', () => {
    let component: () => RegenerateChecklistComponent;
    let bsModalRef: BsModalRefMock;

    beforeEach(() => {
        bsModalRef = new BsModalRefMock();
        component = (): RegenerateChecklistComponent => {
            const c = new RegenerateChecklistComponent(bsModalRef);

            return c;
        };
    });

    it('should create the component', () => {
        expect(component).toBeTruthy();
    });

    it('should initialise the component', () => {
        const c = component();
        const rows = [
            {questionId: 100, hasYesCharge: true, yesAnswer: true},
            {questionId: 101, hasNoCharge: true, noAnswer: true},
            {questionId: 102, hasLetters: true},
            {questionId: 103, hasLetters: false}
        ];
        c.checklistQuestions = {
            rows
        };

        c.ngOnInit();

        expect(c.listOfCharges.length).toEqual(2);
        expect(c.listOfLetters.length).toEqual(1);
    });

    it('should initialise lict of common docs with the component', () => {
        const c = component();
        const generalDocs = [
            {documentId: 100, regenerateGeneralDoc: true},
            {documentId: 101, regenerateGeneralDoc: false}
        ];
        c.checklistQuestions = {
            generalDocs
        };

        c.ngOnInit();

        expect(c.listOfCommonDocuments.length).toEqual(2);
    });

    it('should close on cancel', () => {
        const c = component();
        c.cancel();

        expect(bsModalRef.hide).toHaveBeenCalled();
    });

    it('should close on proceed', () => {
        const c = component();
        c.proceed();

        expect(bsModalRef.hide).toHaveBeenCalled();
    });

    it('should flag user selected items to be regenerated', () => {
        const rows = [
            {questionId: 100, hasYesCharge: true},
            {questionId: 101, hasYesCharge: true},
            {questionId: 102, hasLetters: true},
            {questionId: 103, hasLetters: false}
        ];
        const c = component();
        c.checklistQuestions = {
            rows
        };
        let regenerationItem = {questionId: 100};
        c.toggleItem(regenerationItem, true, 'charge');
        let item = _.find(c.checklistQuestions.rows, (v: any) => {
            return v.questionId === regenerationItem.questionId;
        });

        expect(item.regenerateCharges).toBeTruthy();

        regenerationItem = {questionId: 102};
        c.toggleItem(regenerationItem, true, 'letter');
        item = _.find(c.checklistQuestions.rows, (v: any) => {
            return v.questionId === regenerationItem.questionId;
        });

        expect(item.regenerateDocuments).toBeTruthy();
    });

    it('should flag user selected documents to be regenerated', () => {
        const rows = [
            {questionId: 100, hasYesCharge: true},
            {questionId: 103, hasLetters: false}
        ];
        const generalDocs = [
            {documentId: 100, regenerateGeneralDoc: true},
            {documentId: 101, regenerateGeneralDoc: false}
        ];
        const c = component();
        c.checklistQuestions = {
            rows,
            generalDocs
        };
        const regenerationItem = {documentId: 100};
        c.toggleGeneralDoc(regenerationItem, true);
        const item = _.find(c.checklistQuestions.generalDocs, (v: any) => {
            return v.documentId === regenerationItem.documentId;
        });

        expect(item.regenerateGeneralDoc).toBeTruthy();
    });
});