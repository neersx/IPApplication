import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { map } from 'rxjs/operators';

export interface ILinkService {
    get(): Array<LinksViewModel>;
}

export class LinksViewModel {
    constructor(public group: string, public links: any) { }
}
@Injectable()
export class LinkService {

    links: Array<LinksViewModel>;
    constructor(private readonly http: HttpClient) {
    }

    get = (): Observable<Array<LinksViewModel>> => {
        if (this.links && this.links.length > 0) { return of(this.links); }

        return this.http.get('api/portal/links')
            .pipe(
                map((data: any) => {
                    if (data && data.length > 0) {
                        this.links = [];
                        data.forEach(value => {
                            this.links.push(new LinksViewModel(value.group, value.links));
                        });
                    }

                    return this.links;
                }));
    };
}