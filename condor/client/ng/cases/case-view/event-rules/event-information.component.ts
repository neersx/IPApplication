import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { CommonUtilityService } from 'core/common.utility.service';
import { EventRulesDetailsModel } from './event-rule-details.model';

@Component({
    selector: 'ipx-event-information',
    templateUrl: './event-information.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class EventInformationComponent {

    dateFormat: any;
    @Input() eventRuleDetails: EventRulesDetailsModel;
    @Input() canMaintainWorkflow: boolean;

    constructor(
        private readonly commonUtilityService: CommonUtilityService
    ) { }
}