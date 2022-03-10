import { Injectable, OnDestroy } from '@angular/core';
import { AppContextService } from 'core/app-context.service';
import { MessageBroker } from 'core/message-broker';
import { Subject } from 'rxjs';
import { take } from 'rxjs/operators';

@Injectable({
    providedIn: 'root'
})
export class TimeMessagingService implements OnDestroy {
    private readonly messageSubject: Subject<any> = new Subject<any>();
    private readonly bindings: Array<string> = [];
    message$ = this.messageSubject.asObservable();

    constructor(private readonly messageBroker: MessageBroker,
        private readonly appContextService: AppContextService) {
        this.appContextService.appContext$
            .pipe(take(1))
            .subscribe(ctx => {
                this.subscribeToTimerMessages(ctx.user.identityId);
            });
    }

    private subscribeToTimerMessages(identityId: number): void {
        const binding = 'time.recording.timerStarted' + identityId;
        this.bindings.push(binding);
        this.messageBroker.subscribe(binding, (message: any) => {
            this.messageSubject.next({ ...message });
        });
        this.messageBroker.connect();
    }

    ngOnDestroy(): void {
        this.messageBroker.disconnectBindings(this.bindings);
        this.messageBroker.disconnect();
    }
}