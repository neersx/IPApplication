import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { TranslateFakeLoader, TranslateLoader, TranslateModule, TranslateService } from '@ngx-translate/core';
import { StateService } from '@uirouter/core';
import { NotificationServiceMock } from 'mocks';
import { TooltipModule } from 'ngx-bootstrap/tooltip';
import { of } from 'rxjs';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { DetailPageNavComponent } from './detail-page-nav.component';

describe('PageTitleSaveComponent', () => {
    let component: DetailPageNavComponent;
    const notificationService: NotificationServiceMock = new NotificationServiceMock();
    let fixture: ComponentFixture<DetailPageNavComponent>;

    beforeEach(async(() => {
        TestBed.configureTestingModule({
            imports: [
                TooltipModule.forRoot(),
                TranslateModule.forRoot({
                    loader: {
                        provide: TranslateLoader,
                        useClass: TranslateFakeLoader
                    }
                })
            ],
            providers: [
                TranslateService,
                {
                    provide: StateService, useValue: {
                        params: {
                            id: '3'
                        },
                        go: (routerState, routerParams) => undefined
                    }
                },
                {
                    provide: IpxNotificationService, useValue: notificationService
                }
            ],
            declarations: [
                DetailPageNavComponent
            ]
        }).compileComponents().catch();
    }));

    beforeEach(() => {
        fixture = TestBed.createComponent(DetailPageNavComponent);
        component = fixture.componentInstance;
        fixture.detectChanges();
    });
    it('should create the component', async(() => {
        expect(component).toBeTruthy();
        expect(component.paramKey).toBe('id');
        expect(component.navigate).toBeDefined();
    }));
    describe('navigate', () => {
        beforeEach(() => {
            spyOn(component.$state, 'go').and.callThrough();
        });
        it('returns if no id', () => {
            component.routerState = 'detail.page';
            component.navigate(undefined);

            // tslint:disable-next-line: no-unbound-method
            expect(component.$state.go).not.toHaveBeenCalled();
        });

        it('navigates to routerState with correct paramaters', () => {
            component.routerState = 'detail.page';
            component.paramKey = 'detailId';
            component.ids = [123, 234];
            component.navigate(123);

            // tslint:disable-next-line: no-unbound-method
            expect(component.$state.go).toHaveBeenCalledWith('detail.page', { detailId: 123 }, { reload: true });
        });

        it('navigates to routerState with correct paramaters for id objects', () => {
            component.routerState = 'caseView';
            component.paramKey = 'rowKey';
            component.ids = [{
                key: '123',
                value: 123
            }];
            const id = '123';
            component.navigate(id);

            // tslint:disable-next-line: no-unbound-method
            expect(component.$state.go).toHaveBeenCalledWith('caseView', { rowKey: id, id: 123 }, { reload: true });
        });

        it('should call change next and previous keys if noparams provided when navigate', () => {
            jest.spyOn(component.nextResult, 'emit');
            component.ids = [{
                key: '123',
                value: 123
            },
            {
                key: '124',
                value: 124
            },
            {
                key: '125',
                value: 123
            }
            ];
            component.noParams = true;
            component.navigate('123');
            expect(component.$state.go).not.toHaveBeenCalled();
            expect(component.nextId).toEqual('124');
            expect(component.prevId).toEqual('122');
            expect(component.nextResult.emit).toHaveBeenCalledWith(123);
        });
        it('should cancel navigation when there are any unsaved changes and user choses to cancel', () => {
            component.ids = [{
                key: '123',
                value: 123
            },
            {
                key: '124',
                value: 124
            },
            {
                key: '125',
                value: 123
            }
            ];
            component.noParams = true;
            component.hasUnsavedChanges = true;
            const modalServiceSpy = notificationService.openDiscardModal.mockReturnValue({ content: { confirmed$: of() } });
            component.navigate('123');
            expect(modalServiceSpy).toHaveBeenCalledWith();
        });

    });
    describe('processIds sets navigation ids ', () => {
        it('using list of ids', () => {
            component.ids = [1, 2, 3, 4, 5];
            // tslint:disable-next-line:no-lifecycle-call
            component.ngOnInit();

            expect(component.prevId).toBe('2');
            expect(component.current).toBe(3);
            expect(component.nextId).toBe('4');
            expect(component.total).toBe(5);
            expect(component.visible).toBe(true);

            component.detailNavigate.subscribe(g => {
                expect(g).toEqual({ currentPage: 2 });
            });
        });

        it('using list of id objects', () => {
            component.ids = [{
                key: '1',
                value: 1
            },
            {
                key: '2',
                value: 2
            },
            {
                key: '3',
                value: 3
            },
            {
                key: '4',
                value: 4
            },
            {
                key: '5',
                value: 5
            }
            ];
            component.paramKey = 'id';
            // tslint:disable-next-line:no-lifecycle-call
            component.ngOnInit();

            expect(component.prevId).toEqual('2');
            expect(component.current).toEqual(3);
            expect(component.nextId).toEqual('4');
            expect(component.total).toEqual(5);
            expect(component.visible).toBe(true);

            component.detailNavigate.subscribe(g => {
                expect(g).toEqual({ currentPage: 2 });
            });
        });

        it('using lastSearch', () => {
            const allIds = { then: (cb) => cb([5, 4, 3, 2, 1]) };

            component.lastSearch = {
                getAllIds: () => allIds
            };

            fixture.detectChanges();
            // tslint:disable-next-line:no-lifecycle-call
            component.ngOnInit();

            expect(component.prevId).toBe('4');
            expect(component.current).toBe(3);
            expect(component.nextId).toBe('2');
            expect(component.lastId).toBe('1');
            expect(component.total).toBe(5);
            expect(component.visible).toBe(true);
            component.detailNavigate.subscribe(g => {
                expect(g).toEqual({ currentPage: 2 });
            });
        });

        it('hidden if id does not exist in the list', () => {
            component.ids = [5, 6, 7, 8];

            expect(component.current).not.toBeDefined();
            expect(component.firstId).not.toBeDefined();
            expect(component.prevId).not.toBeDefined();
            expect(component.nextId).not.toBeDefined();
            expect(component.lastId).not.toBeDefined();
            expect(component.total).not.toBeDefined();
            expect(component.visible).toBe(false);
        });

        it('hidden if id does not exist in the list on id objects', () => {
            component.ids = [{
                key: '5',
                value: 5
            }, {
                key: '6',
                value: 6
            }, {
                key: '7',
                value: 7
            }, {
                key: '8',
                value: 8
            }];
            component.paramKey = 'id';
            expect(component.current).not.toBeDefined();
            expect(component.firstId).not.toBeDefined();
            expect(component.prevId).not.toBeDefined();
            expect(component.nextId).not.toBeDefined();
            expect(component.lastId).not.toBeDefined();
            expect(component.total).not.toBeDefined();
            expect(component.visible).toBe(false);
        });
    });
    describe('navigation icons disabled ', () => {
        it('should disable last navigation icon', () => {
            component.lastId = '10';
            component.current = 10;
            let r = component.isLastDisabled();
            expect(r).toBe(true);

            component.current = 2;
            r = component.isLastDisabled();
            expect(r).toBe(false);
        });
        it('should disable first navigation icon', () => {
            component.firstId = '1';
            component.current = 1;
            let r = component.isFirstDisabled();
            expect(r).toBe(true);

            component.current = 2;
            r = component.isFirstDisabled();
            expect(r).toBe(false);
        });
        it('should disable previous navigation icon', () => {
            let r = component.isPreviousDisabled();
            expect(r).toBe(true);

            component.prevId = '1';
            r = component.isPreviousDisabled();
            expect(r).toBe(false);
        });
        it('should disable next navigation icon', () => {
            component.canFetchNext = false;
            let r = component.isNextDisabled();
            expect(r).toBe(true);

            component.nextId = '2';
            component.canFetchNext = true;
            r = component.isNextDisabled();
            expect(r).toBe(false);
        });
    });
});
