import { Directive, HostBinding, HostListener } from '@angular/core';

@Directive({ selector: '[autoHighlighted]' })

export class AutoCompleteHighlightedDirective {
    @HostBinding('class.highlighted') private isHighlighted = false;

    @HostListener('mouseover') onMouseOver(): any {
        this.isHighlighted = true;
    }

    @HostListener('mouseout') onMouseOut(): any {
        this.isHighlighted = false;
    }
}
