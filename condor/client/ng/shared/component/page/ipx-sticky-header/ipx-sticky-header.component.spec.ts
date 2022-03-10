import { async } from '@angular/core/testing';
import { ElementRefMock, Renderer2Mock } from 'mocks';
import { IpxStickyHeaderComponent } from './ipx-sticky-header.component';

describe('PageTitleSaveComponent', () => {
    let component: IpxStickyHeaderComponent;
    const el = new ElementRefMock();
    const renderer = new Renderer2Mock();

    it('should create the component', async(() => {
        component = new IpxStickyHeaderComponent(el, renderer as any);
        expect(component).toBeTruthy();
    }));

});