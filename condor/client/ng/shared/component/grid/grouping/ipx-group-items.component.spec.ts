import { async } from '@angular/core/testing';
import { InjectorMock } from 'mocks';
import { GroupItemsComponent } from './ipx-group-items.component';

describe('GroupItemsComponent', () => {
  let c: GroupItemsComponent;
  const injector = new InjectorMock();
  beforeEach(() => {
    c = new GroupItemsComponent(injector);
  });

  it('should create the component', async(() => {
    expect(c).toBeTruthy();
  }));

  it('should call Oninit ', async(() => {
    c.columns = [{ field: 'detail', title: '', template: true }];
    c.ngOnInit();
    expect(c.gridoptions.columns.length).toEqual(1);
  }));

  it('should call Oninit to check has children is false', async(() => {
    const dataitem = {
      rowKey: '360',
      caseKey: -132,
      id: '-132_360'
    };
    const task = [{
      id: 'OpenDms',
      text: 'searchResults.dms.title',
      icon: 'cpa-icon cpa-icon-file-text-folder-open-o'
    }];
    c.menuProvider = {
      getConfigurationTaskMenuItems: jest.fn().mockReturnValue(task)
    };
    c.initializeTaskItems(dataitem);
    expect(c.taskItems).toEqual(task);

  }));

  it('Emit item on Group Item Clicked', async(() => {
    const event = { caseKey: -48 };
    spyOn(c.groupItemClicked, 'emit');
    c.onDataItemClicked(event);
    expect(c.groupItemClicked.emit).toHaveBeenCalledWith(event);
  }));
});