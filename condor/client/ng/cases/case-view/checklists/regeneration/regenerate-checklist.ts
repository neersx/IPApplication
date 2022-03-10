import { ChangeDetectionStrategy, Component, EventEmitter, OnInit, Output } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import * as _ from 'underscore';

@Component({
    selector: 'regenerate-checklist',
    templateUrl: 'regenerate-checklist.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class RegenerateChecklistComponent implements OnInit {

    @Output() private readonly proceedData = new EventEmitter<any>();
    @Output() private readonly dontSave = new EventEmitter();
    modalRef: BsModalRef;
    checklistQuestions: any;
    listOfCharges: any = null;
    listOfLetters: any = null;
    listOfCommonDocuments: any = null;

    constructor(bsModalRef: BsModalRef) {
        this.modalRef = bsModalRef;
    }
    ngOnInit(): void {
        const yesCharges = _.where(this.checklistQuestions.rows, { hasYesCharge: true, yesAnswer: true });
        const noCharges = _.where(this.checklistQuestions.rows, { hasNoCharge: true, noAnswer: true });
        this.listOfCharges = [...yesCharges, ...noCharges];
        this.listOfLetters = _.where(this.checklistQuestions.rows, { hasLetters: true });
        this.listOfCommonDocuments = this.checklistQuestions.generalDocs;
        _.forEach(this.listOfCommonDocuments, (i: any) => {
            i.regenerateGeneralDoc = false;
        });
    }

    proceed(): void {
        this.proceedData.emit();
        this.modalRef.hide();
    }

    cancel(): void {
        this.dontSave.emit();
        this.modalRef.hide();
    }

    byQuestionId = (_index: number, item: any): number => {
        return item.questionId;
    };

    byDocumentId = (_index: number, item: any): number => {
        return item.documentId;
    };

    toggleItem = (item: any, value: boolean, type: string) => {
        const x = _.find(this.checklistQuestions.rows, (v: any) => {
            return v.questionId === item.questionId;
        });
        if (type === 'charge') {
            x.regenerateCharges = value;
        }
        if (type === 'letter') {
            x.regenerateDocuments = value;
        }
    };

    toggleGeneralDoc = (item: any, value: boolean) => {
        const x = _.find(this.checklistQuestions.generalDocs, (v: any) => {
            return v.documentId === item.documentId;
        });
        x.regenerateGeneralDoc = value;
    };
}