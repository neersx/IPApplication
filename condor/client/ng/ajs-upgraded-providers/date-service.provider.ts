import { FactoryProvider, NgModule } from '@angular/core';

export abstract class DateService {
    culture: any;
    dateFormat: any;
    useDefault: any;
    getParseFormats: any;
    getExpandedParseFormats: any;
    format: any;
    adjustTimezoneOffsetDiff: any;
    shortDateFormat: any;
}

export const dateServiceFactory = (service: ng.auto.IInjectorService) => service.get('dateService');

export const dateServiceProvider: FactoryProvider = {
    provide: DateService,
    useFactory: dateServiceFactory,
    deps: ['$injector']
};
