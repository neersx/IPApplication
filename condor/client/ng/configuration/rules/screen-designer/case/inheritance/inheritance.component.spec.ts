import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock, StateServiceMock } from 'mocks';
import { ScreenDesignerService } from '../../screen-designer.service';
import { InheritanceComponent } from './inheritance.component';

describe('InheritanceComponent', () => {
  let component: InheritanceComponent;
  let localSettings: any;
  let inheritanceService: {
    getInheritance: jest.Mock
  };
  let screenDesignerService: {
    popState: jest.Mock,
    pushState: jest.Mock
  };
  let cdRef: ChangeDetectorRefMock;
  beforeEach(() => {
    cdRef = new ChangeDetectorRefMock();
    const stateMock = new StateServiceMock();
    localSettings = new LocalSettingsMock();
    inheritanceService = {
      getInheritance: jest.fn()
    };
    screenDesignerService = {
      popState: jest.fn(),
      pushState: jest.fn()
    };

    component = new InheritanceComponent(inheritanceService as any, cdRef as any, ScreenDesignerService as any, stateMock as any, localSettings);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('collapseAll', () => {
    it('clears keys on collapse all', () => {
      component.keys = ['test1', 'test2', 'test3'];

      component.collapseAll();

      expect(component.keys).toEqual([]);
    });
  });

  describe('noneSelected', () => {
    it('returns false if any keys', () => {
      component.keys = ['1'];

      const noneSelected = component.noneSelected();

      expect(noneSelected).toEqual(false);
    });

    it('returns true if no keys', () => {
      component.keys = [];

      const noneSelected = component.noneSelected();

      expect(noneSelected).toEqual(true);
    });
  });

  describe('allSelected', () => {
    it('returns false if any keys', () => {
      component.keys = ['1'];
      component.treeNodes = {
        totalCount: 2
      };

      const noneSelected = component.allSelected();

      expect(noneSelected).toEqual(false);
    });

    it('returns true if no keys', () => {
      component.keys = ['1', '2'];
      component.treeNodes = {
        totalCount: 2
      };

      const noneSelected = component.allSelected();

      expect(noneSelected).toEqual(true);
    });
  });

  describe('handleExpand', () => {
    it('should add to keys if keys doesnt have the index already', () => {
      component.keys = [];

      component.handleExpand({ index: '1' });

      expect(component.keys).toEqual(['1']);
    });

    it('should not add to keys if keys has the index already', () => {
      component.keys = ['1'];

      component.handleExpand({ index: '1' });

      expect(component.keys).toEqual(['1']);
    });

    it('should not add to keys if keys has the index already, and existing indexes should be maintained', () => {
      component.keys = ['1', '2'];

      component.handleExpand({ index: '1' });

      expect(component.keys).toEqual(['1', '2']);
    });
  });

  describe('handleCollapse', () => {
    it('should remove any keys with the index', () => {
      component.keys = ['1', '1', '2'];

      component.handleCollapse({ index: '1' });

      expect(component.keys).toEqual(['2']);
    });
  });

  describe('isExpanded', () => {
    it('should return true if its in the list', () => {
      component.keys = ['1', '2'];

      const expanded = component.isExpanded({} as any, '1');

      expect(expanded).toEqual(true);
    });

    it('should return false if its in the list', () => {
      component.keys = ['1', '2'];

      const expanded = component.isExpanded({} as any, '3');

      expect(expanded).toEqual(false);
    });
  });
});
