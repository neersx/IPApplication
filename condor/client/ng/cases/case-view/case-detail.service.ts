import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, OnDestroy } from '@angular/core';
import { CaseNavigationService } from 'cases/core/case-navigation.service';
import { BehaviorSubject, Observable, of, Subject } from 'rxjs';
import { map } from 'rxjs/operators';
import { ValidationError } from 'shared/component/forms/validation-error';

@Injectable()
export class CaseDetailService implements OnDestroy {
    hasPendingChanges$ = new BehaviorSubject<boolean>(false);
    resetChanges$ = new BehaviorSubject<boolean>(false);
    errorDetails$ = new Subject<Array<ValidationError>>();

    getCaseIdCalls: Map<string, Promise<any>>;

    constructor(private readonly http: HttpClient, private readonly casenavigationService: CaseNavigationService) {
    }

    ngOnDestroy(): void {
        this.getCaseIdCalls = undefined;
    }

    getCaseId$(caseRef: string): Promise<any> {
        return new Promise((resolve, reject) => {
            if (this.getCaseIdCalls == null) {
                this.getCaseIdCalls = new Map();
            }

            if (!this.getCaseIdCalls.has(caseRef)) {
                this.getCaseIdCalls.set(caseRef, this.http.get('api/case/caseId', {
                    params: new HttpParams()
                        .set('caseRef', encodeURI(caseRef))
                }).toPromise());
            }

            this.getCaseIdCalls.get(caseRef)
                .then((val) => {
                    resolve(val);
                }).catch(reject)
                .finally(() => this.getCaseIdCalls.delete(caseRef));
        });
    }

    getOverview$(id: any, rowKey: Number): Observable<any> {
        const caseKey = this.casenavigationService.getCaseKeyFromRowKey(rowKey);

        return this.http.get('api/case/' + encodeURI((id) ? id : caseKey.toString()) + '/overview');
    }

    getIppAvailability$(id: Number): Observable<IppAvailability> {
        return this.http.get('api/case/' + encodeURI(id.toString()) + '/ipp-availability') as Observable<IppAvailability>;
    }

    getCaseWebLinks$(caseKey: Number): Observable<any> {
        return this.http.get('api/case/' + encodeURI(caseKey.toString()) + '/weblinks');
    }

    getCaseSupportUri$(caseKey: Number): Observable<any> {
        return this.http.get('api/case/' + encodeURI(caseKey.toString()) + '/support-email');
    }

    getScreenControl$(caseKey: Number, programId: string): Observable<any> {
        return this.http.get('api/case/screencontrol/' + encodeURI(caseKey.toString()) + '/' + (programId ? encodeURI(programId) : ''));
    }

    getCaseViewData$(): Observable<any> {
        return this.http.get('api/case/caseview');
    }

    getCaseRenewalsData$(caseKey: Number, screenCriteriaKey: Number): Observable<any> {
        return this.http.get('api/case/' + encodeURI(caseKey.toString()) + '/renewals', {
            params: new HttpParams()
                .set('screenCriteriaKey', JSON.stringify(screenCriteriaKey))
        });
    }

    getCaseProgram$(programId: string): Observable<any> {
        return this.http.get('api/case/program?programId=' + (programId ? encodeURI(programId) : ''));
    }

    getStandingInstructions$(caseKey: Number): Observable<any> {
        return this.http.get('api/case/' + encodeURI(caseKey.toString()) + '/standing-instructions');
    }

    getCaseInternalDetails$(caseKey: Number): Observable<any> {
        return this.http.get('api/case/' + encodeURI(caseKey.toString()) + '/internal-details');
    }
    getImportanceLevelAndEventNoteTypes$(): Observable<{ importanceLevel: number, importanceLevelOptions: any, requireImportanceLevel: boolean, eventNoteTypes: any, canAddCaseAttachments: any }> {
        return this.http.get('api/case/importance-levels-note-types')
            .pipe(map((data: any) => {
                return {
                    importanceLevel: data.importanceLevel,
                    importanceLevelOptions: data.importanceLevelOptions,
                    requireImportanceLevel: data.requireImportanceLevel,
                    eventNoteTypes: data.eventNoteTypes,
                    canAddCaseAttachments: data.canAddCaseAttachments
                };
            }));
    }

    getCustomContentData$(caseKey: Number, itemKey: Number): Observable<any> {
        return this.http.get('api/custom-content/case/' + encodeURI(caseKey.toString()) + '/item/' + encodeURI(itemKey.toString()));
    }

    updateCaseDetails$(data: TopicMaintenanceSaveModel): Observable<any> {

        return this.http.post('api/case/maintenance', data);
    }

    getCaseChecklistTypes$(caseKey: Number): Observable<any> {
        return this.http.get('api/case/' + encodeURI(caseKey.toString()) + '/checklist-types');
    }

    getCaseChecklistData$(caseKey: Number, checklistCriteriaKey: Number, queryParams: any): Observable<any> {
        return this.http.get('api/case/' + encodeURI(caseKey.toString()) + '/checklists', {
            params: new HttpParams()
                .set('checklistCriteriaKey', JSON.stringify(checklistCriteriaKey))
                .set('params', JSON.stringify(queryParams))
        });
    }

    getCaseChecklistDataHybrid$(caseKey: Number, checklistCriteriaKey: Number): Observable<any> {
        return this.http.get('api/case/' + encodeURI(caseKey.toString()) + '/checklists-hybrid', {
            params: new HttpParams()
                .set('checklistCriteriaKey', JSON.stringify(checklistCriteriaKey))
        });
    }

    getChecklistDocuments$(caseKey: Number, checklistCriteriaKey: Number): Observable<any> {
        return this.http.get('api/case/' + encodeURI(caseKey.toString()) + '/checklistsDocuments', {
            params: new HttpParams()
                .set('checklistCriteriaKey', JSON.stringify(checklistCriteriaKey))
        });
    }

    eventDate(dateTime: Date): Date {
        if (dateTime instanceof Date) {
            return new Date(Date.UTC(dateTime.getFullYear(), dateTime.getMonth(), dateTime.getDate()));
        }

        return null;
    }
}
export class TopicMaintenanceSaveModel {
    caseKey: number;
    program: string;
    topics: { [key: string]: any };
    isPoliceImmediately?: boolean;
    forceUpdate: boolean;
    ignoreSanityCheck: boolean;
}

export interface IppAvailability {
    file: FileAvailability;
}

export interface FileAvailability {
    isEnabled: boolean;
    canView: boolean;
    canInstruct: boolean;
    hasViewAccess: boolean;
}

export interface TopicChanges {
    key: string;
    data: any;
}