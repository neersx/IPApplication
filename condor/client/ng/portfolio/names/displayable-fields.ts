import { Injectable } from '@angular/core';
import * as _ from 'underscore';

export class NameTypeFieldFlags {
     static readonly address = 2;
     static readonly assignDate = 8;
     static readonly dateCommenced = 16;
     static readonly dateCeased = 32;
     static readonly billPercentage = 64;
     static readonly inherited = 128;
     static readonly remarks = 1024;
     static readonly telecom = 4096;
     static readonly nationality = 8192;
}

@Injectable()
export class DisplayableNameTypeFieldsHelper {
    private readonly map = {
        address: NameTypeFieldFlags.address,
        assignDate: NameTypeFieldFlags.assignDate,
        dateCommenced: NameTypeFieldFlags.dateCommenced,
        dateCeased: NameTypeFieldFlags.dateCeased,
        billPercentage: NameTypeFieldFlags.billPercentage,
        inherited: NameTypeFieldFlags.inherited,
        remarks: NameTypeFieldFlags.remarks,
        nationality: NameTypeFieldFlags.nationality,
        telecom: NameTypeFieldFlags.telecom
    };

    static factory(): any {
        const instance = () =>
            new DisplayableNameTypeFieldsHelper();

        return instance;
    }

    shouldDisplay = (flag: number, flagValues: Array<number>): boolean => {
        return _.find(flagValues, (fv) => {
            // tslint:disable:no-bitwise

            return flag & fv;
            // tslint:enable:no-bitwise
        }) !== undefined;
    };

    mapFlag = (flagName: string): number => {

        return this.map[flagName];
    };
}