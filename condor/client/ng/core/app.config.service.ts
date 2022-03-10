import { Injectable } from '@angular/core';
import { TypeAheadConfigProvider } from '../shared/component/typeahead/ipx-typeahead/typeahead.config.provider';

@Injectable()
export class AppConfigurationService {
    constructor(private readonly typeAheadConfigProvider: TypeAheadConfigProvider) { }
    init(): Promise<void> {
        return new Promise<void>((resolve) => {
            this.typeAheadConfigProvider.configuration();
            resolve();
        });
    }
}
