import { ChangeDetectionStrategy, Component, Input } from '@angular/core';
import { DatesLogicDetailInfo, FailureActionType } from './event-rule-details.model';

@Component({
    selector: 'ipx-dates-logic',
    templateUrl: './dates-logic.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class DatesLogicComponent {

    @Input() datesLogicInfo: Array<DatesLogicDetailInfo>;
    failureActionType = FailureActionType;

    byItem = (index: number, item: any): string => item;
}