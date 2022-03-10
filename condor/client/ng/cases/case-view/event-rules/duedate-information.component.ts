import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DueDateCalculationInfo } from './event-rule-details.model';

@Component({
    selector: 'ipx-duedate-information',
    templateUrl: './duedate-information.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class DueDateCalculationInformationComponent implements OnInit {

    satisfyingEventGridOptions: IpxGridOptions;
    dateComparisonGridOptions: IpxGridOptions;
    @Input() dueDateCalculationInfo: DueDateCalculationInfo;
    @Input() canMaintainWorkflow: boolean;

    ngOnInit(): void {
        this.satisfyingEventGridOptions = this.buildSatisfyingEventsGridOptions();
        this.dateComparisonGridOptions = this.buildDateComparisonGridOptions();
    }

    private readonly buildSatisfyingEventsGridOptions = (): IpxGridOptions => {
        const options: IpxGridOptions = {
            draggable: true,
            hideHeader: true,
            read$: () => {
                return of(this.dueDateCalculationInfo.dueDateSatisfiedBy).pipe(delay(100));
            },
            columns: [
                {
                    title: '',
                    field: 'eventKey',
                    width: 130
                },
                {
                    title: '',
                    field: 'formattedDescription'
                }],
            navigable: false
        };

        return options;
    };

    private readonly buildDateComparisonGridOptions = (): IpxGridOptions => {
        const options: IpxGridOptions = {
            hideHeader: true,
            draggable: true,
            read$: () => {
                return of(this.dueDateCalculationInfo.dueDateComparison).pipe(delay(100));
            },
            columns: [
                {
                    title: '',
                    field: 'leftHandSide',
                    width: 400
                },
                {
                    title: '',
                    field: 'comparison',
                    width: 50
                },
                {
                    title: '',
                    field: 'rightHandSide'
                }],
            navigable: false
        };

        return options;
    };

    byItem = (index: number, item: any): string => item;
}