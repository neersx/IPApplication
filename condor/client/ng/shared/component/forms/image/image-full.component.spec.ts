import { ImageFullComponent } from './image-full.component';

describe('CaseImageFullComponent', () => {
  let c: ImageFullComponent;

  beforeEach(() => {
    c = new ImageFullComponent({} as any);
  });

  it('should create the component & set the default value', (() => {
    expect(c).toBeTruthy();
    expect(c.titleLimit).toEqual(80);
  }));
});
