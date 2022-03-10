import { DatePipe } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { ChangeDetectorRef, Injectable } from '@angular/core';
import * as moment from 'moment';
import { Observable } from 'rxjs';
import { take, takeWhile } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { TimeRecordingService } from './time-recording/time-recording-service';

@Injectable()
export class ItemDateValidator {
    isItemDateWarningSuppressed: boolean;
    constructor(private readonly http: HttpClient, private readonly timeService: TimeRecordingService,
        private readonly datePipe: DatePipe, private readonly ipxNotificationService: IpxNotificationService,
        private readonly cdRef: ChangeDetectorRef) { }

    validateItemDate = (date: any, url: string, itemDateControl: any) => {
        if (date) {
            this.isItemDateWarningSuppressed = false;
            const transDate = this.datePipe.transform(this.timeService.toLocalDate(date, true), 'yyyy-MM-dd');
            this.validateItemDate$(transDate, url).subscribe((res: any) => {
                if (res && res.HasError) {
                    if (res.ValidationErrorList[0].WarningCode) {
                        if (res.ValidationErrorList[0].WarningCode === 'AC124') {
                            this.ipxNotificationService.openInfoModal('accounting.billing.warning', 'accounting.errors.AC124');
                        } else {
                            const confirmationRef = this.ipxNotificationService.openConfirmationModal('Warning', 'field.errors.' + res.ValidationErrorList[0].WarningCode.toLowerCase(), 'Proceed', 'Cancel');
                            confirmationRef.content.confirmed$.pipe(take(1)).subscribe(() => {
                                this.isItemDateWarningSuppressed = true;
                            });
                            confirmationRef.content.cancelled$.pipe(takeWhile(() => !!confirmationRef))
                                .subscribe(() => {
                                    if (!moment().isSame(moment(date), 'day')) {
                                        itemDateControl.setValue(new Date());
                                    }
                                });
                        }
                    } else {
                        switch (res.ValidationErrorList[0].ErrorCode) {
                            case 'AC126': itemDateControl.setErrors({ ac126: true });
                                break;
                            case 'AC208': itemDateControl.setErrors({ ac208: true });
                                break;
                            case 'AC215': itemDateControl.setErrors({ ac215: true });
                                break;
                            case 'AC216': itemDateControl.setErrors({ ac216: true });
                                break;
                            case 'AC217': itemDateControl.setErrors({ ac217: true });
                                break;
                            case 'AC207': itemDateControl.setErrors({ ac207: true });
                                break;
                            default: {
                                break;
                            }
                        }

                        itemDateControl.markAsDirty();
                        itemDateControl.markAsTouched();
                    }
                    this.cdRef.detectChanges();

                    return;
                }
            });
        } else {
            itemDateControl.setValue(new Date());
        }
    };

    validateItemDate$(date: any, url: string): Observable<any> {
        return this.http.get(`api/accounting/${url}/validate`, {
            params: {
                itemDate: date.toString()
            }
        });
    }
}