import { async } from '@angular/core/testing';
import { GroupDetailComponent } from './ipx-group.detail.component';

describe('GroupDetailComponent', () => {
    let c: GroupDetailComponent;
    beforeEach(() => {
        c = new GroupDetailComponent();
    });

    it('should create the component', async(() => {
        expect(c).toBeTruthy();
    }));

    it('should call Oninit to check has children is true', async(() => {
        c.items = [{ items: [1, 2, 3] }];
        c.ngOnInit();
        expect(c.hasChildren).toEqual(true);
    }));

    it('should call Oninit to check has children is false', async(() => {
        c.items = [];
        c.ngOnInit();
        expect(c.hasChildren).toEqual(false);
    }));

    it('Emit item on Group Item Clicked', async(() => {
        const event = { caseKey: -48 };
        spyOn(c.groupItemClicked, 'emit');
        c.onGroupItemClicked(event);
        expect(c.groupItemClicked.emit).toHaveBeenCalledWith(event);
    }));
});