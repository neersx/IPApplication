import { Renderer2Mock } from 'mocks';
import { HeaderComponent } from './ipx-header.component';

describe('HeaderComponent', () => {
    let component: HeaderComponent;
    let renderer2Mock: any;
    let animationBuilder: any;
    beforeEach(() => {
        renderer2Mock = new Renderer2Mock();
        animationBuilder = {};
        component = new HeaderComponent(renderer2Mock, animationBuilder);
    });
    it('should initialize HeaderComponent', () => {
        expect(component).toBeTruthy();
    });
});