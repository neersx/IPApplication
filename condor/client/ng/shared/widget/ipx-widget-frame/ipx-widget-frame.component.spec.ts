import { IpxWidgetFrameComponent } from './ipx-widget-frame.component';

describe('IpxWidgetFrameComponent', () => {
  let component: IpxWidgetFrameComponent;

  beforeEach(() => {
    component = new IpxWidgetFrameComponent();
  });
  describe('onInit', () => {
    it('should not expand if no setting', () => {
      component.expandSetting = null;
      component.expand = jest.fn();

      component.ngOnInit();

      expect(component.expand).not.toHaveBeenCalled();
    });

    it('should not expand if setting false', () => {
      component.expandSetting = { getLocal: false } as any;
      component.expand = jest.fn();

      component.ngOnInit();

      expect(component.expand).not.toHaveBeenCalled();
    });

    it('should not expand if setting true', () => {
      component.expandSetting = { getLocal: true } as any;
      component.expand = jest.fn();

      component.ngOnInit();

      expect(component.expand).toHaveBeenCalled();
    });
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('toggleHeight', () => {
    it('should call makeHalfHeight if not expanded', () => {
      component.makeHalfHeight = jest.fn();
      component.toggleHeight({});

      expect(component.makeHalfHeight).toHaveBeenCalledTimes(1);

      component.expanded = true;
      component.toggleHeight({});

      expect(component.makeHalfHeight).toHaveBeenCalledTimes(1);
    });
  });

  describe('expand', () => {
    it('should set expanded to true and call makeFullHeight', () => {
      component.makeFullHeight = jest.fn();
      expect(component.expanded).toBeFalsy();

      component.expand();

      expect(component.expanded).toBeTruthy();
      expect(component.makeFullHeight).toHaveBeenCalledTimes(1);
    });
  });

  describe('restore', () => {
    it('should set expanded to false and call makeHalfHeight', () => {
      component.expanded = true;
      component.makeHalfHeight = jest.fn();
      component.autoFit = false;
      component.restore();

      expect(component.expanded).toBeFalsy();
      expect(component.makeHalfHeight).toHaveBeenCalledTimes(1);
    });

    it('should set autoFit to true', () => {
      component.expanded = true;
      component.makeHalfHeight = jest.fn();
      component.autoFit = true;
      component.restore();
      expect(component.expanded).toBeFalsy();
      expect(component.height).toEqual('');
    });
  });

  describe('makeFullHeight', () => {
    it('should set height to empty', () => {
      component.height = 'test';
      component.makeFullHeight();

      expect(component.height).toEqual('100vh');
    });
  });

  describe('makeHalfHeight', () => {
    it('should set height to the correct value', () => {
      component.height = 'test';
      component.makeHalfHeight();

      expect(component.height).toEqual('465px');
    });

    it('should set height and emit the value to propagateChange', () => {
      component.height = 'test';
      spyOn(component.propagateChange, 'emit');
      component.makeFullHeight();
      expect(component.height).toEqual('100vh');
      expect(component.propagateChange.emit).toHaveBeenCalled();
    });
  });
});
