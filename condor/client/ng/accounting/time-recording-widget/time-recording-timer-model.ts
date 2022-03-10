import { DateFunctions } from 'shared/utilities/date-functions';

export class TimerSeed {
    startDateTime: Date;
    staffNameId?: number;
    caseKey?: number;

    constructor(data: any) {
        Object.assign(this, data);
    }

    readonly makeServerReady = (): string => {
        this.startDateTime = DateFunctions.toLocalDate(this.startDateTime, false);

        return JSON.stringify(this);
    };
}