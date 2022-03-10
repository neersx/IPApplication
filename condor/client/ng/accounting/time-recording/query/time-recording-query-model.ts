import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { DateFunctions } from 'shared/utilities/date-functions';
import * as _ from 'underscore';

export class TimeSearchQuery {
    staffId?: number;
    fromDate?: Date;
    toDate?: Date;
    isPosted: boolean;
    isUnposted: boolean;
    asDebtor: boolean;
    asInstructor: boolean;
    narrativeSearch?: string;
    entity?: number;

    constructor(data?: any) {
        if (!!data) {
            Object.assign(this, data);
        }
    }
}

export class TimeRecordingQueryData {
    name: any;
    cases: Array<any>;
    isPosted: boolean;
    isUnposted: boolean;
    asInstructor: boolean;
    asDebtor: boolean;
    narrative: string;
    activity: any;
    entity: any;
    staff: any;
    hideContinued: boolean;
    fromDate?: Date;
    toDate?: Date;
    caseIds: Array<number>;
    activityId?: number;
    nameId?: number;
    selectedPeriodId?: number;

    constructor(data?: any) {
        if (!!data) { Object.assign(this, data); }
    }

    getServerReady = (): TimeSearchQuery => {
        return new TimeSearchQuery({
            fromDate: !!this.fromDate ? DateFunctions.toLocalDate(this.fromDate, true) : null,
            toDate: !!this.toDate ? DateFunctions.toLocalDate(this.toDate, true) : null,
            caseIds: _.pluck(this.cases, 'key'),
            activityId: !!this.activity ? this.activity.key : null,
            nameId: !!this.name ? this.name.key : null,
            staffId: !!this.staff ? this.staff.key : null,
            isPosted: this.isPosted,
            isUnposted: this.isUnposted,
            asDebtor: this.asDebtor,
            asInstructor: this.asInstructor,
            entity: _.isNumber(this.entity) ? this.entity : null,
            narrativeSearch: this.narrative
        });
    };
}

export class BatchSelectionDetails {
    staffNameId?: number;

    entryNumbers?: Array<number>;

    reverseSelection?: ReverseSelection;

    constructor(data: any) {
        Object.assign(this, data);
    }
}

export class ReverseSelection {
    constructor(private readonly searchParams: TimeSearchQuery, private readonly queryParams: GridQueryParameters, private readonly exceptEntryNumbers?: Array<number>) {
    }
}

export class TimeSearchPeriods {
    id: number;
    description: string;
}