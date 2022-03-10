import { Injectable } from '@angular/core';
import * as _ from 'underscore';
import { PageHelperService } from './page-helper.service';

@Injectable({
    providedIn: 'root'
})
export class LastSearchService {
    args: any;
    ids: any;
    method: any;
    methodName: string;

    constructor(private readonly pageHelper: PageHelperService) { }

    setInitialData = (args: any): void => {
        if (!args.method) {
            throw new Error('method is required');
        }
        this.method = args.method;
        this.methodName = args.methodName;
        this.args = Array.isArray(args.args) ? {...args.args} : {...Array.prototype.slice.call(args.args)};
    };

    getPageSize = () => {
        if (this.args && this.args[1]) {
            return this.args[1].take;
        }
    };

    getPageForId = (id) =>
        this.pageHelper.getPageForId(this.ids, id, this.getPageSize());

    setAllIds = (paramIds) => {
        this.ids = paramIds.slice(0);
    };

    getAllIds = (): Promise<any> => {
        let promise: Promise<any>;
        if (this.ids) {
            promise = new Promise<any>((resolve) => { resolve(this.ids); });
        } else {
            if (this.args && this.args.length) {
                const queryParams = this.args[this.args.length - 1];
                queryParams.getAllIds = true;
            }

            promise = this.method.apply(self, this.args).then((response) => {
                const data = response.data || response;
                const ids = Array.isArray(data) ? data : _.pluck(response.data || response, 'id');
                this.setAllIds(ids);

                return ids;
            });
        }

        return promise;
    };
}
