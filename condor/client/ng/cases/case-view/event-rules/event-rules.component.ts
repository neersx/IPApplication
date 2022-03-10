import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import * as _ from 'underscore';
import { ActionEventsRequestModel } from '../actions/action-model';
import { DatesLogicDetailInfo, DocumentsInfo, DueDateCalculationInfo, EventRulesDetailsModel, EventRulesRequest, EventUpdateInfo, RemindersInfo } from './event-rule-details.model';
import { EventRuleDetailsService } from './event-rule-details.service';

@Component({
    selector: 'ipx-event-rules',
    templateUrl: './event-rules.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class EventRulesComponent implements OnInit {

    modalRef: BsModalRef;
    eventRulesRequest: EventRulesRequest;
    eventNo: number;
    eventRuleDetails: EventRulesDetailsModel;
    canMaintainWorkflow: boolean;
    dueDateCalculationInfo: DueDateCalculationInfo;
    remindersInfo: Array<RemindersInfo>;
    documentsInfo: Array<DocumentsInfo>;
    datesLogicInfo: Array<DatesLogicDetailInfo>;
    eventUpdateInfo: EventUpdateInfo;
    isLoading = true;
    hasPreviousState = false;
    currentKey: number;
    q: ActionEventsRequestModel;

    navData: {
        keys: Array<any>,
        totalRows: number,
        pageSize: number,
        fetchCallback(currentIndex: number): any
    };

    constructor(
        bsModalRef: BsModalRef, private readonly service: EventRuleDetailsService, private readonly cdr: ChangeDetectorRef, private readonly navService: GridNavigationService) {
        this.modalRef = bsModalRef;
    }

    ngOnInit(): void {
        this.eventRulesRequest = {
            caseId: this.q.criteria.caseKey,
            eventNo: this.eventNo,
            cycle: this.q.criteria.cycle,
            action: this.q.criteria.actionId
        };
        // tslint:disable-next-line: prefer-object-spread
        this.navData = Object.assign({}, this.navService.getNavigationData(), {
            fetchCallback: (currentIndex: number): any => {
                return this.navService.fetchNext$(currentIndex).toPromise();
            }
        });
        this.currentKey = this.navData.keys.filter(x => x.value === this.eventNo.toString())[0].key;
        this.getEventDetails();
    }

    onClose(): void {
        this.modalRef.hide();
    }

    getEventDetails(): void {
        this.service.getEventDetails$(this.eventRulesRequest).subscribe(res => {
            this.eventRuleDetails = res;
            this.dueDateCalculationInfo = this.eventRuleDetails ? this.eventRuleDetails.dueDateCalculationInfo : null;
            this.remindersInfo = this.eventRuleDetails ? this.eventRuleDetails.remindersInfo : null;
            this.documentsInfo = this.eventRuleDetails ? this.eventRuleDetails.documentsInfo : null;
            this.datesLogicInfo = this.eventRuleDetails ? this.eventRuleDetails.datesLogicInfo : null;
            this.eventUpdateInfo = this.eventRuleDetails ? this.eventRuleDetails.eventUpdateInfo : null;
            this.isLoading = false;
            this.cdr.detectChanges();
        }, (error) => {
            this.isLoading = false;
            this.cdr.detectChanges();
        });
    }

    getNextEventDetails(next: number): any {
        const nextEvent = {
            eventNo: next
        };
        this.eventRulesRequest = { ...this.eventRulesRequest, ...nextEvent };
        this.getEventDetails();
    }
}