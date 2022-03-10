'use strict'
namespace inprotech.portfolio.cases {

    export class NameTypeFieldFlags {
        public static readonly address = 2;
        public static readonly assignDate = 8;
        public static readonly dateCommenced = 16;
        public static readonly dateCeased = 32;
        public static readonly billPercentage = 64;
        public static readonly inherited = 128;
        public static readonly remarks = 1024;
        public static readonly telecom = 4096;
        public static readonly nationality = 8192;
    }

    export class DisplayableNameTypeFieldsHelper {
        private map = {
            address: NameTypeFieldFlags.address,
            assignDate: NameTypeFieldFlags.assignDate,
            dateCommenced: NameTypeFieldFlags.dateCommenced,
            dateCeased: NameTypeFieldFlags.dateCeased,
            billPercentage: NameTypeFieldFlags.billPercentage,
            inherited: NameTypeFieldFlags.inherited,
            remarks: NameTypeFieldFlags.remarks,
            nationality: NameTypeFieldFlags.nationality,
            telecom: NameTypeFieldFlags.telecom
        }

        static factory() {
            let instance = () =>
                new DisplayableNameTypeFieldsHelper();
            return instance;
        }

        constructor() {}

        public shouldDisplay = (flag: number, flagValues: number[]): boolean => {
            return _.find(flagValues, (fv) => {
                // tslint:disable:no-bitwise
                return flag & fv;
                // tslint:enable:no-bitwise
            }) !== undefined;
        }

        public mapFlag = (flagName: string): number => {
            return this.map[flagName];
        }
    }

    angular.module('inprotech.portfolio.cases').factory('displayableFields', DisplayableNameTypeFieldsHelper.factory());
}