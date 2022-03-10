import { async } from '@angular/core/testing';
import { GroupHeaderItemComponent } from './ipx-group.header.item.component';

describe('GroupHeaderItemComponent', () => {
    let c: GroupHeaderItemComponent;
    beforeEach(() => {
        c = new GroupHeaderItemComponent();
    });

    it('should create the component', async(() => {
        expect(c).toBeTruthy();
    }));

    it('should call Oninit', async(() => {
        c.ngOnInit();
        expect(c.gridOptions).toBeDefined();
        expect(c.gridOptions.columns.length).toEqual(1);
    }));

    it('Emit item on Group Item Clicked', async(() => {
        const event = { caseKey: -48 };
        spyOn(c.groupItemClicked, 'emit');
        c.onGroupItemClicked(event);
        expect(c.groupItemClicked.emit).toHaveBeenCalledWith(event);
    }));
});