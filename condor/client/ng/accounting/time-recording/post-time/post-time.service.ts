import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, Subject } from 'rxjs';
import { map, take } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { PostResult, PostTimeView } from './post-time.model';

@Injectable()
export class PostTimeService {
    private readonly basePostTimeUrl = 'api/accounting/time-posting';
    private readonly postResultSubject: Subject<PostResult>;

    postResult$: Observable<PostResult>;

    constructor(private readonly http: HttpClient,
        private readonly ipxNotificationService: IpxNotificationService) {
        this.postResultSubject = new Subject<PostResult>();
        this.postResult$ = this.postResultSubject.asObservable();
    }

    getView(): Observable<PostTimeView> {
        let headers: HttpHeaders;
        headers = new HttpHeaders({ 'cache-response': 'true' });

        return this.http.get(`${this.basePostTimeUrl}/view`,
            { headers });
    }

    getDates(queryParams?, staffNameId?: number, from?: Date, to?: Date, postAll?: boolean): Observable<any> {
        const q = queryParams || {
            skip: 0,
            take: 10
        };
        const url = `${this.basePostTimeUrl}/getDates` + (_.isNumber(staffNameId) ? `/${staffNameId}` : '');

        return this.http.get(url, {
            params: {
                params: JSON.stringify(q),
                dates: JSON.stringify({from: postAll ? from : null, to: postAll ? to : null})
            }
        }).pipe(map((res: any) => {
            _.each(res.data, (item: any) => {
                item.rowKey = item.date + '-' + item.staffNameId;
            });

            return res;
        }));
    }

    postTime(selectedEntityKey: number, datesToPost: any, staffNameId?: number): void {
        this.http.post(`${this.basePostTimeUrl}/post`, {
            entityKey: selectedEntityKey,
            selectedDates: !!datesToPost ? _.pluck(datesToPost, 'date') : null,
            staffNameId
        }).pipe(take(1))
            .subscribe((res: PostResult) => {
                if (!!res.hasWarning) {
                    const confirmationRef = this.ipxNotificationService.openConfirmationModal('Warning', `accounting.errors.${res.error.alertID}`, 'Proceed', 'Cancel');
                    confirmationRef.content.confirmed$.pipe(take(1)).subscribe(() => {
                        this.http.post(`${this.basePostTimeUrl}/post`, { entityKey: selectedEntityKey, selectedDates: datesToPost, staffNameId, warningAccepted: true })
                            .pipe(take(1))
                            .subscribe((nextRes: PostResult) => {
                                this.postResultSubject.next(nextRes);
                            });
                    });
                } else {
                    this.postResultSubject.next(res);
                }
            });
    }

    postSelectedEntry = (postEntryDetails: any): void => {
        this.http.post(`${this.basePostTimeUrl}/postEntry`, postEntryDetails)
            .pipe(take(1))
            .subscribe((res: PostResult) => {
                if (!!res.hasWarning) {
                    const confirmationRef = this.ipxNotificationService.openConfirmationModal('Warning', `accounting.errors.${res.error.alertID}`, 'Proceed', 'Cancel');
                    confirmationRef.content.confirmed$.pipe(take(1)).subscribe(() => {
                        this.http.post(`${this.basePostTimeUrl}/postEntry`, { ...postEntryDetails, warningAccepted: true })
                            .pipe(take(1))
                            .subscribe((nextRes: PostResult) => {
                                this.postResultSubject.next(nextRes);
                            });
                    });
                } else {
                    this.postResultSubject.next(res);
                }
            });
    };

    postForAllStaff = (selectedEntityKey?: number, datesToPost?: Array<any>, fromDate?: Date, toDate?: Date): void => {
        this.http.post(`${this.basePostTimeUrl}/postForAllStaff`, {
            entityKey: selectedEntityKey,
            selectedDates: datesToPost,
            warningAccepted: false,
            searchParams: {
                fromDate,
                toDate
            }
        }).pipe(take(1))
            .subscribe((res: PostResult) => {
                if (!!res.hasWarning) {
                    const confirmationRef = this.ipxNotificationService.openConfirmationModal('Warning', `accounting.errors.${res.error.alertID}`, 'Proceed', 'Cancel');
                    confirmationRef.content.confirmed$.pipe(take(1)).subscribe(() => {
                        this.http.post(`${this.basePostTimeUrl}/postForAllStaff`, {
                                ...datesToPost,
                                warningAccepted: true
                            })
                            .pipe(take(1))
                            .subscribe((nextRes: PostResult) => {
                                this.postResultSubject.next(nextRes);
                            });
                    });
                } else {
                    this.postResultSubject.next(res);
                }
            });
    };
}