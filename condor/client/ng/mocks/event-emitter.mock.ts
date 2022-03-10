export class EventEmitterMock<T extends any> {
    subscribeMethod: any;
    emit = jest.fn((t: T) => {
        if (this.subscribeMethod) {
            this.subscribeMethod(t);
        }

        return t;
    });
    subscribe = jest.fn((t) => { this.subscribeMethod = t; });
    pipe = jest.fn();
}