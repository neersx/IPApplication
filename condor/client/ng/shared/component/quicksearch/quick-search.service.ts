import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { ListItem } from './quick-search.component';

@Injectable()
export class QuickSearchService {
    constructor(private readonly http: HttpClient, private readonly translate: TranslateService) { }

    get(term): Observable<any> {
        return this.http.get<Array<ListItem>>('api/quicksearch/typeahead?q=' + encodeURIComponent(term))
        .pipe(
            map((response: any) => {
                if (response && response.data && this.translate) {
                    response.data.forEach(x => {
                        if (x.using) {
                            x.using = this.translate.instant('quickSearch.using.' + x.using);
                        }
                    });
                }

                return response;
            }));
    }
}
