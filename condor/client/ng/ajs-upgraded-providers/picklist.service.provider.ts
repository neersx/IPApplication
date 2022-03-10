import { FactoryProvider } from '@angular/core';
const serviceName = 'picklistService';

export abstract class PicklistService {
    abstract openModal(scope: undefined, options: PicklistOptions): any;
}

export class PicklistOptions {
    type?: string;
    displayName?: string;
    picklistDisplayName?: string;
    selectedItems?: any;
    label?: string;
    keyField?: string;
    textField?: string;
    apiUrl?: string;
    columns?: Array<{ title: string, field: string }>;
    extendQuery?: (query: any) => any;
    size?: 'sm' | 'lg' | 'xl';
    multipick?: boolean;
    showPreview?: boolean;
    picklistCanMaintain?: boolean;
    canAddAnother?: boolean;
    columnMenu?: boolean;
    appendPicklistLabel?: boolean;
    initialViewData?: any;
    searchValue?: any;
    previewable?: boolean;
    dimmedColumnName?: string;
    picklistNewSearch?: boolean;
}

export const picklistServiceFactory = (injector: ng.auto.IInjectorService) =>
    injector.get(serviceName);

export const picklistServiceProvider: FactoryProvider = {
    provide: PicklistService,
    useFactory: picklistServiceFactory,
    deps: ['$injector']
};
