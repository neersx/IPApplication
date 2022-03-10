import { Renderer2Mock } from 'mocks';
import { IpxIframeComponent } from './ipx-iframe.component';

describe('IpxIframeComponent', () => {
  let component: IpxIframeComponent;
  const renderer = new Renderer2Mock();

  beforeEach(() => {
    component = new IpxIframeComponent(renderer as any);
  });

  it('should create component', () => {
    expect(component).toBeTruthy();
  });

  it('should check onLoad properties', () => {
    component.srcUrl = '#';
    component.onLoad();
    expect(component.isLoaded).toBeTruthy();
  });

});
