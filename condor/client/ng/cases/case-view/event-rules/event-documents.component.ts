import { ChangeDetectionStrategy, Component, Input } from '@angular/core';
import * as _ from 'underscore';
import { DocumentsInfo } from './event-rule-details.model';

@Component({
    selector: 'ipx-event-documents',
    templateUrl: './event-documents.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class EventDocumentsComponent {
    @Input() documentsInfo: Array<DocumentsInfo>;

    byItem = (index: number, item: any): string => item;
}