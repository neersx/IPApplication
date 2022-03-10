import { ChangeDetectorRefMock, EventEmitterMock } from 'mocks';
import { TopicType } from './ipx-topic.model';
import { IpxTopicsComponent } from './ipx-topics.component';

describe('IpxTopicsComponent', () => {
    let component: IpxTopicsComponent;
    let cdr: ChangeDetectorRefMock;
    let setCountEmitter: EventEmitterMock<number>;

    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        setCountEmitter = new EventEmitterMock<number>();
        setCountEmitter.subscribe = jest.fn((inputFn) => {
            setCountEmitter.emit = inputFn;
        });

        component = new IpxTopicsComponent({ nativeElement: { querySelector: () => ({}) } } as any, {} as any, {} as any, {} as any, cdr as any);

        component.options = {
            topics: [],
            actions: []
        };
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('should evaluate topic type when type not mentioned', () => {
        // tslint:disable-next-line:no-lifecycle-call
        component.ngOnInit();

        expect(component.isSimpleTopic).toBeFalsy();
    });

    it('should evaluate topic type when type is simple', () => {
        component.type = TopicType.Simple;
        // tslint:disable-next-line:no-lifecycle-call
        component.ngOnInit();

        expect(component.isSimpleTopic).toBeTruthy();
    });

    it('should flatten topics having subtopics', () => {
        component.options = {
            topics: [{
                key: 'events',
                title: 'Event Control'
            },
            {
                key: 'eventsGroup',
                title: 'caseview.events.header',
                topics: [{
                    key: 'due',
                    title: 'caseview.events.due'
                }, {
                    key: 'occurred',
                    title: 'caseview.events.occurred'
                }]
            }],
            actions: []
        };

        // tslint:disable-next-line:no-lifecycle-call
        component.ngOnInit();

        expect(component.flattenTopics.length).toBe(4);
        expect(component.flattenTopics[1].isGroupSection).toBeTruthy();
    });

    it('should call the setCount, on emit', () => {
        const count = 5;
        component.options = {
            topics: [{
                key: 'events',
                title: 'Event Control',
                setCount: setCountEmitter as any
            }]
        };

        component.ngOnInit();
        component.options.topics[0].setCount.emit(count);

        expect(component.options.topics[0].count).toBe(count);
        expect(cdr.markForCheck).toHaveBeenCalled();
    });

    it('should reload the required components', () => {
        component.options = {
            topics: [{
                key: 'action',
                title: 'Action Control'
            },
            {
                key: 'events',
                title: 'Event Control'
            },
            {
                key: 'eventsGroup',
                title: 'caseview.events.header',
                topics: [{
                    key: 'due',
                    title: 'caseview.events.due'
                }, {
                    key: 'occurred',
                    title: 'caseview.events.occurred'
                }]
            }]
        };

        component.ngOnInit();
        component.topicRefs = [{
            topicData: {
                key: 'action',
                component: 'action'
            },
            reloadComponent: jest.fn()
        },
        {
            topicData: {
                key: 'due',
                component: 'due'
            },
            reloadComponent: jest.fn()
        }] as any;
        component.reloadTopics(['action']);
        expect(component.topicRefs[0].reloadComponent).toBeCalled();
    });

    describe('doAction', () => {
        it('should emit the key of the action its called with to the parent component', () => {
            (component as any).actionClicked = { emit: jest.fn() } as any;
            component.doAction({key: 'testValue'} as any);

            expect(component.actionClicked.emit).toHaveBeenCalledWith('testValue');
        });
    });
});