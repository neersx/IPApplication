import { Pipe, PipeTransform } from '@angular/core';
import { DomSanitizer } from '@angular/platform-browser';
import { NGXLogger } from 'ngx-logger';

@Pipe({
    name: 'typeaheadHighlight'
})

export class TypeaheadHighlight implements PipeTransform {
    constructor(private readonly _sanitizer: DomSanitizer, private readonly logger: NGXLogger) { }
    transform(matchItem: any, query: any): string {
        let matchedItem: any;
        if (matchItem) {
            matchedItem = matchItem.toString();
        }
        if (this.containsHtml(matchedItem)) {
            this.logger.warn('Unsafe use of typeahead please use ngSanitize');
        }
        matchedItem = query ? ('' + matchedItem).replace(new RegExp(this.escapeRegexp(query), 'gi'), '<strong>$&</strong>') : matchedItem; // Replaces the capture string with a the same string inside of a "strong" tag

        if (!this._sanitizer) {
            matchedItem = this._sanitizer.bypassSecurityTrustHtml(matchedItem);
        }

        return matchedItem;
    }

    escapeRegexp = (queryToEscape) => queryToEscape.replace(/([.?*+^$[\]\\(){}|-])/g, '\\$1');

    containsHtml = (matchItem) => /<.*>/g.test(matchItem);

}
