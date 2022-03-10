export class WindowParentMessagingServiceMock {
  postLifeCycleMessage = jest.fn();
  postNavigationMessage = jest.fn();
  postAutosizeMessage = jest.fn();
  postRequestForData = jest.fn().mockReturnValue(Promise.resolve());
}
