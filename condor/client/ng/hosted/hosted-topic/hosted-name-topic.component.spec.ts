import { AppContextServiceMock } from 'core/app-context.service.mock';
import { NotificationServiceMock } from 'mocks';
import { WindowParentMessagingServiceMock } from 'mocks/window-parent-messaging.service.mock';
import { NameViewServiceMock } from 'names/name-view/name-view.service.mock';
import { of } from 'rxjs';
import { HostedNameTopicComponent } from './hosted-name-topic.component';

describe('HostedNameTopicComponent', () => {
    let component: HostedNameTopicComponent;
    let nameViewService: NameViewServiceMock;
    let notificationService: NotificationServiceMock;
    let wpMessageService: WindowParentMessagingServiceMock;
    let context: AppContextServiceMock;
    let confirmNotificationService: {
        openConfirmationModal: jest.Mock
    };
    describe('HostedNameTopicComponent saving supplier', () => {
        beforeEach(() => {
            nameViewService = new NameViewServiceMock();
            notificationService = new NotificationServiceMock();
            wpMessageService = new WindowParentMessagingServiceMock();
            context = new AppContextServiceMock();
            confirmNotificationService = {
                openConfirmationModal: jest.fn()
            };
            component = new HostedNameTopicComponent(nameViewService as any, notificationService as any, wpMessageService as any, confirmNotificationService as any, context as any);
            component.topic = {
                params: {
                    viewData: {
                        nameKey: '23',
                        hostId: 'supplierHost'
                    }
                }
            } as any;
            component.componentRef = {
                getChanges: () => {
                    return {
                        localBalanceTotal: 1
                    };
                },
                formData: {
                    hasOutstandingPurchases: false
                }
            };
        });

        it('should create the component', () => {
            component.ngOnInit();
            expect(component).toBeTruthy();
            expect(component.showWebLink).toBeTruthy();
        });

        it('post a dirty flag after saved for supplier', () => {
            nameViewService.maintainName$ = jest.fn().mockReturnValue(of({ status: 'success', savedSuccessfully: true }));
            component.saveNameData(null, true);
            expect(wpMessageService.postLifeCycleMessage).toHaveBeenCalledWith({
                action: 'onChange',
                target: 'supplierHost',
                payload: {
                    isDirty: false
                }
            });
        });
    });

    describe('HostedNameTopicComponent validate supplier', () => {
        const notificationRef = {
            content: {
                confirmed$: of ({}),
                cancelled$: of ({})
            }
        };
        beforeEach(() => {
            nameViewService = new NameViewServiceMock();
            notificationService = new NotificationServiceMock();
            wpMessageService = new WindowParentMessagingServiceMock();
            context = new AppContextServiceMock();
            confirmNotificationService = {
                openConfirmationModal: jest.fn()
            };
            component = new HostedNameTopicComponent(nameViewService as any, notificationService as any, wpMessageService as any, confirmNotificationService as any, context as any);
            component.topic = {
                params: {
                    viewData: {
                        nameKey: '23',
                        hostId: 'supplierHost'
                    }
                }
            } as any;
            component.componentRef = {
                getChanges: () => {
                    return {
                        localBalanceTotal: 1
                    };
                },
                formData: {
                    hasOutstandingPurchases: true,
                    oldRestrictionKey: 1,
                    restrictionKey: 2
                }
            };
            component.saveNameData = jest.fn();
        });

        it('asks to change all creditor restrictions when it changes for supplier credit items', done => {
            confirmNotificationService.openConfirmationModal = jest.fn().mockReturnValue(notificationRef);
            component.ngOnInit();
            component.save(null, true);
            expect(confirmNotificationService.openConfirmationModal).toHaveBeenCalledWith(null, 'nameview.supplierDetails.restrictionConfirmMessage', null, null, null, null, false);
            notificationRef.content.confirmed$.subscribe(() => {
                expect(component.saveNameData).toHaveBeenCalled();
                done();
            });
        });
    });
});