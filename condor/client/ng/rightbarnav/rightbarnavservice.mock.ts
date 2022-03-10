export class RightBarNavServiceMock {
    registerDefault = jest.fn();
    getDefault = jest.fn();
    onAdd = jest.fn();
    onAddContextual = jest.fn();
    onAddKot = jest.fn();
    registercontextuals = jest.fn();
    notifyNewNavComponent = jest.fn();
    registerKot = jest.fn();
    onCloseRightBarNav$ = { next: jest.fn() };
}