export class BusMock {
    channel = jest.fn().mockReturnValue({
        subscribe: jest.fn(),
        unsubscribe: jest.fn(),
        broadcast: jest.fn()
    });
    singleSubscribe = jest.fn();
}