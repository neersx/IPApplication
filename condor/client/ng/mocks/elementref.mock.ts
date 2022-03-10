export class ElementRefMock {
    nativeElement: any = {
        querySelector: jest.fn(),
        hasAttribute: jest.fn(),
        getAttribute: jest.fn()
    };
}

export class ElementRefTypeahedMock {
    nativeElement = { getAttribute: jest.fn(), querySelector: jest.fn(), hasAttribute: jest.fn() };
}