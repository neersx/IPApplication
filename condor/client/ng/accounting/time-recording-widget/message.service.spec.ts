import { AppContextServiceMock } from 'core/app-context.service.mock';
import { MessageBroker } from 'mocks/message-broker.mock';
import { of } from 'rxjs';
import { TimeMessagingService } from './message.service';
import { TimerDetail } from './time-recording-widget.component';

describe('TimeMessagingService', () => {
    let messageBroker: MessageBroker;
    let appContextService: AppContextServiceMock;
    let service: TimeMessagingService;

    beforeEach(() => {
        messageBroker = new MessageBroker();
        appContextService = new AppContextServiceMock();
        service = new TimeMessagingService(messageBroker as any, appContextService as any);
    });
    describe('broadcast message', () => {
        it('are subscribed to', () => {
            expect(messageBroker.subscribe).toHaveBeenCalled();
            expect(messageBroker.subscribe.mock.calls[0][0]).toEqual('time.recording.timerStarted9');
            expect(messageBroker.connect).toHaveBeenCalled();
        });

        it('receives the broadcasted message', () => {
            const runStartTime = new Date();
            runStartTime.setHours(10);
            runStartTime.setMinutes(30);
            const message = { hasActiveTimer: true, basicDetails: new TimerDetail({ start: runStartTime }) };
            messageBroker.broadcast(message);
            messageBroker.subscribe(() => {
                expect(service.message$).toEqual(of({ message }));
            });
        });

        it('are unsubscribed on destroy', () => {
            service.ngOnDestroy();
            expect(messageBroker.disconnectBindings).toHaveBeenCalled();
            expect(messageBroker.disconnectBindings.mock.calls[0][0]).toEqual(['time.recording.timerStarted9']);
        });
    });
});