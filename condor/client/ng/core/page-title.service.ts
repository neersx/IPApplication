import { Injectable, Injector } from '@angular/core';

@Injectable()
export class PageTitleService {
    private rootscope: any;
    constructor(private readonly injector: Injector) {
    }

    setPrefix = (prefix: string, stateName?: string): void => {
        if (!this.rootscope) {
            this.rootscope = this.injector.get('$rootScope');
        }
        this.rootscope.setPageTitlePrefix(prefix, stateName);
    };
}