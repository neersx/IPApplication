import { Pipe, PipeTransform } from '@angular/core';
import { DomSanitizer } from '@angular/platform-browser';

@Pipe({
  name: 'quicksearchHighlight'
})
export class QuicksearchHighlight implements PipeTransform {
  constructor(private readonly _sanitizer: DomSanitizer) {}
  transform(matchItem: any, query: string): string {
    let matchedItem = matchItem;
    if (matchItem == null) {
      return null;
    }

    if (query == null) {
      return matchItem;
    }

    if (
      matchItem.substring(0, query.length).toLowerCase() === query.toLowerCase()
    ) {
        matchedItem =
        '<strong>' +
        matchItem.substring(0, query.length) +
        '</strong>' +
        matchItem.substring(query.length);
    }

    if (!this._sanitizer) {
        matchedItem = this._sanitizer.bypassSecurityTrustHtml(matchedItem);
    }

    return matchedItem;
  }
}
