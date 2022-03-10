import { Injectable } from '@angular/core';
import * as _ from 'underscore';

@Injectable({
    providedIn: 'root'
})
export class PageHelperService {
    getPageForId = (ids: any, id: any, pageSize: number) => {
        if (!pageSize || !ids || !id) {
            return {
                page: -1,
                relativeRowIndex: -1
            };
        }

        if (ids.length > pageSize) {
            let index = 0;

            // tslint:disable-next-line:radix
            index = isNaN(id) || isNaN(ids[0]) ? _.indexOf(ids, id) : _.indexOf(ids, parseInt(id));

            if (index !== -1) {
                return {
                    page: Math.floor(index / pageSize) + 1,
                    relativeRowIndex: (index % pageSize)
                };
            }

            return {
                page: -1,
                relativeRowIndex: -1
            };
        }

        const idIndex = _.indexOf(ids, id);

        return {
            page: idIndex === -1 ? -1 : 1,
            relativeRowIndex: idIndex
        };
    };
}
