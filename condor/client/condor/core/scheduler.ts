namespace inprotech.core {
    export interface IScheduler {
        runOutsideZone(fn: any, ...args: any[]): void;
    }

    export class Scheduler implements IScheduler {

        constructor(private ngZone: any) {

        }

        runOutsideZone(fn: any, ...args: any[]): void {
            this.ngZone.runOutsideAngular(() => {
                fn(args);
            });
        }
    }
    angular.module('inprotech.core').service('scheduler', ['ngZoneService', Scheduler]);
}