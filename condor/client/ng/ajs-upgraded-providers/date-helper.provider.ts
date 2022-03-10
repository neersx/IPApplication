import { FactoryProvider, NgModule } from '@angular/core';

export abstract class DateHelper {
    addDays: any;
    setTime: any;
    getTime: any;
    convertForDatePicker: any;
    areDatesEqual: any;
    abstract toLocal(selectedDate: Date): any;
    addMonths: any;
}

export const dateHelperFactory = (service: ng.auto.IInjectorService) => service.get('dateHelper');

export const dateHelperProvider: FactoryProvider = {
    provide: DateHelper,
    useFactory: dateHelperFactory,
    deps: ['$injector']
};
