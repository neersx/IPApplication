import { ChangeDetectorRefMock, EventEmitterMock } from 'mocks';
import { IpxTopicMenuItemComponent } from './ipx-topic-menu-item.component';
import { Topic } from './ipx-topic.model';

describe('IpxTopicsComponent', () => {
    let component: IpxTopicMenuItemComponent;
    let cdr: ChangeDetectorRefMock;
    let setCountEmitter: EventEmitterMock<number>;

    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        setCountEmitter = new EventEmitterMock<number>();
        setCountEmitter.subscribe = jest.fn((inputFn) => {
            setCountEmitter.emit = inputFn;
        });
        component = new IpxTopicMenuItemComponent(cdr as any);
    });

    it('should initialise by adding subscriber for setCount', () => {
        const topic: Topic = { key: 'A', title: 'title', setCount: setCountEmitter as any };

        expect(component).toBeDefined();
        component.topic = topic as any;

        component.ngOnInit();

        expect(component.topic.setCount.subscribe).toHaveBeenCalled();
    });

    it('should call the setCount, on emit', () => {
        const count = 5;
        const topic: Topic = { key: 'A', title: 'title', setCount: setCountEmitter as any };
        component.topic = topic as any;

        component.ngOnInit();
        component.topic.setCount.emit(count);

        expect(topic.count).toBe(count);
        expect(cdr.markForCheck).toHaveBeenCalled();
    });
});