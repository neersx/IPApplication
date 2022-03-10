export class NotificationServiceMock {
    confirmDelete = () => Promise.resolve();
    alert = jest.fn();
    success = jest.fn();
    info = jest.fn();
}
