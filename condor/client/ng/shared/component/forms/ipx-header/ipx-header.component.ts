import { animate, AnimationBuilder, AnimationFactory, AnimationPlayer, style } from '@angular/animations';
import { ChangeDetectionStrategy, Component, ElementRef, Renderer2 } from '@angular/core';

@Component({
    selector: 'ipx-header',
    templateUrl: './ipx-header.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class HeaderComponent {
    collaps: boolean;
    _animation: AnimationFactory;
    _animationPlayer: AnimationPlayer;
    constructor(private readonly _renderer: Renderer2, private readonly _builder: AnimationBuilder) {
        this.collaps = false;
    }
    toggleCollapse = () => {
        this.collaps = !this.collaps;
        const searchBody = document.querySelector('#searchBody');
        const scrollTop = document.body.scrollTop;
        if (scrollTop >= searchBody.clientHeight + searchBody.clientTop) {
            this._renderer.removeStyle(searchBody, 'overflow');
            this._renderer.removeStyle(searchBody, 'position');
            this._renderer.removeStyle(searchBody, 'height');
            this._renderer.removeStyle(searchBody, 'display');
            if (this._animationPlayer) {
                this._animationPlayer.finish();
                this._animationPlayer.destroy();
            }
            this._animation = this._builder.build([
                style({ overflow: 'hidden', display: 'block', position: 'relative', height: 0 }),
                animate('0.35s ease', style({ height: '*' }))
            ]);
            this._animationPlayer = this._animation.create(searchBody);
            this._animationPlayer.play();
            const ele = document.querySelector('#mainPane');
            ele.scrollTop = 0;

        } else {
            this._renderer.removeStyle(searchBody, 'overflow');
            this._renderer.removeStyle(searchBody, 'position');
            this._renderer.removeStyle(searchBody, 'height');
            this._renderer.removeStyle(searchBody, 'display');
            if (this._animationPlayer) {
                this._animationPlayer.finish();
                this._animationPlayer.destroy();
            }
            this._animation = this._builder.build([
                style({ overflow: 'hidden', display: 'none', position: 'relative' }),
                animate('0.35s ease', style({ height: '0' }))
            ]);
            this._animationPlayer = this._animation.create(searchBody);
            this._animationPlayer.play();
        }
    };
}
