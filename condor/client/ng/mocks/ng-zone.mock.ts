export class NgZoneMock {
    runOutsideAngular = jest.fn().mockImplementation((cb) => { cb(); });
}