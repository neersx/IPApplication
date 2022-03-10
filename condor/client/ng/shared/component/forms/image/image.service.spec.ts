import { ImageService } from './image.service';

describe('Service: Image', () => {
  let httpClientSpy;
  beforeEach(() => {
    httpClientSpy = { get: jest.fn(), post: jest.fn() };
  });

  it('should create an instance', () => {
    const service = new ImageService(httpClientSpy);
    expect(service).toBeTruthy();
  });
});
