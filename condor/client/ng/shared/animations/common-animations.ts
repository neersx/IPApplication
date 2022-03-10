import { animate, state, style, transition, trigger } from '@angular/animations';

export const slideInOutVisible = trigger('slideInOutVisible', [
    state('closed', style({
        height: '0',
        overflow: 'hidden',
        opacity: '0'
    })),
    state('open', style({
        opacity: '1'
    })),
    transition('closed=>open', animate('150ms')),
    transition('open=>closed', animate('150ms'))
]);