import { Injectable } from '@angular/core';
import { PageTitleService } from 'core/page-title.service';
import { BehaviorSubject } from 'rxjs';
import { first, last, skip, take } from 'rxjs/operators';
import { UserIdAndPermissions } from '../time-recording-model';

@Injectable()
export class UserInfoService {
    private readonly userDetailsSubject: BehaviorSubject<UserIdAndPermissions> = new BehaviorSubject<UserIdAndPermissions>(null);
    private readonly isLoggedInUserSubject: BehaviorSubject<boolean> = new BehaviorSubject<boolean>(true);
    userDetails$ = this.userDetailsSubject.asObservable();
    isLoggedInUser$ = this.isLoggedInUserSubject.asObservable();
    loggedInUserNameId: number;

    constructor(private readonly pageTitleService: PageTitleService) {
        this.userDetailsSubject
            .pipe(skip(1), first())
            .subscribe((userDetails) => {
                this.loggedInUserNameId = userDetails.staffId;
            });
    }

    setUserDetails(data: UserIdAndPermissions): void {
        if (!!data.permissions) {
            data.permissions.canAddTimer = this.loggedInUserNameId === data.staffId;
        }
        this.userDetailsSubject.next(data);
        this.isLoggedInUserSubject.next(this.loggedInUserNameId === data.staffId);
        this.pageTitleService.setPrefix(data.displayName);
    }
}
