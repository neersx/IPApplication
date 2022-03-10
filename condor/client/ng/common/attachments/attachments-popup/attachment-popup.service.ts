import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { PopoverDirective } from 'ngx-bootstrap/popover';
import { Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable()
export class AttachmentPopupService {
    private current: PopoverDirective;
    private readonly cache: Map<string, any> = new Map<string, any>();

    constructor(private readonly http: HttpClient) { }

    hideExcept = (popup: PopoverDirective): void => {
        if (this.current && this.current !== popup) {
            this.current.hide();
        }
        this.current = popup;
    };

    clearCache = (): void => {
        if (this.cache) {
            this.cache.clear();
        }
    };

    getAttachments$ = (caseId: number, eventNo: number, eventCycle: number): Observable<any> => {
        const key = `${caseId}-${eventNo}-${eventCycle}`;
        if (this.cache.has(key)) {

            return of(this.cache.get(key));
        }
        const url = `api/case/${caseId}/${eventNo}/${eventCycle}/attachments-recent`;

        return this.http.get(url)
            .pipe(tap(x => this.cache.set(key, x)));
    };
}