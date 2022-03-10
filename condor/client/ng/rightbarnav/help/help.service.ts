import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { map } from 'rxjs/operators';

export interface IHelpService {
    get(): any;
}

export class HelpModel {
    constructor(public inprotechHelpLink: string, public wikiHelpLink: string, public contactUsEmailAddress: string, public credits: Array<String>, public cookieConsentActive: boolean) { }
}

@Injectable()
export class HelpService implements IHelpService {

    helpData: HelpModel;
    constructor(private readonly http: HttpClient) {
    }

    get = (): Observable<HelpModel> => {
        if (this.helpData) { return of(this.helpData); }

        return this.http.get('api/portal/help')
            .pipe(
                map((data: any) => {
                    this.helpData = new HelpModel(data.inprotechHelpLink, data.wikiHelpLink, data.contactUsEmailAddress, data.credits, data.cookieConsentActive);

                    return this.helpData;
                }));
    };
}
