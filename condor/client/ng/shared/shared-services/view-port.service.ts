import { ElementRef, Injectable } from '@angular/core';

@Injectable({
    providedIn: 'root'
})

export class ViewPortService {
    isInView = (elementRef: ElementRef) => {
        const rect = elementRef.nativeElement.getBoundingClientRect();

        return (
            rect.top >= 0 &&
            rect.left >= 0 &&
            rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
            rect.right <= (window.innerWidth || document.documentElement.clientWidth)
        );
    };
}