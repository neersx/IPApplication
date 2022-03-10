export class StateServiceMock {
    go = jest.fn();
    $current = { name: jest.spyOn };
    params = { queryKey: '11,22,233', rowKey: '1,2' };
    reload = jest.fn();
    current = { name: jest.spyOn };
    transitionTo = jest.fn();
}