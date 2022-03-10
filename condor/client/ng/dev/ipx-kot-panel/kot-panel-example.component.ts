import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { KotModel } from 'rightbarnav/keepontopnotes/keep-on-top-notes-models';
import { RightBarNavService } from 'rightbarnav/rightbarnav.service';

@Component({
    selector: 'kot-panel-example',
    templateUrl: './kot-panel-example.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class KotPanelExampleComponent implements OnInit {
    kotNotes: Array<KotModel>;
    textValue: string;
    constructor(private readonly rightNavService: RightBarNavService) { }

    ngOnInit(): void {
        this.kotNotes = [
            {
                note: 'Kot note 1 very large text for testing. Kot note 1 very large text for testing. Kot note 1 very large text for testing. Kot note 1 very large text for testing. Kot note 1 very large text for testing. Kot note 1 very large text for testing. Kot note 1 very large text for testing. Kot note 1 very large text for testing. Kot note 1 very large text for testing.Kot note 1 very large text for testing. Kot note 1 very large text for testing. Kot note 1 very large text for testing. Kot note 1 very large text for testing.',
                caseRef: '1234/a',
                backgroundColor: '#e3c0b4'
            },
            {
                note: 'Kot note 2',
                name: 'Asparagus',
                nameTypes: 'Instructor, Debtor',
                backgroundColor: '#ceb5e5'
            },
            {
                note: 'Kot note 3 very very large text for testing. Kot note 3 very large text for testing. Kot note 3 very large text for testing. Kot note 3 very large text for testing. Kot note 1 very large text for testing. Kot note 1 very large text for testing. Kot note 3 very large text for testing. Kot note 3 very large text for testing. Kot note 3 very large text for testing.Kot note 3 very large text for testing. Kot note 3 very large text for testing. Kot note 3 very large text for testing. Kot note 3 very large text for testing. Kot note 3 very large text for testing. Kot note 3 very large text for testing. Kot note 3 very large text for testing. Kot note 3 very large text for testing. Kot note 3 very large text for testing. Kot note 3 very large text for testing. Kot note 3 very large text for testing. Kot note 3 very large text for testing. Kot note 1 very large text for testing.Kot note 1 very large text for testing. Kot note 3 very large text for testing. Kot note 3 very large text for testing. Kot note 3 very large text for testing.',
                name: 'Brimstone',
                nameTypes: 'Agent'
            },
            {
                note: 'Kot note 4',
                name: 'Test4',
                nameTypes: 'Agent'
            },
            {
                note: 'Kot note 5',
                name: 'Test5',
                nameTypes: 'Agent'
            }
        ];

        this.rightNavService.registerKot(this.kotNotes);
    }
}