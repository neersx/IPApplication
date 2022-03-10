import { Injectable } from '@angular/core';
@Injectable()
export class FocusService {
    autoFocus = (element: any, latency?: number) => {
        if (element) {
            const elRef = element.nativeElement || element;
            setTimeout(() => {
                const focusElem = elRef.querySelector('*[ipx-autofocus]') || elRef;
                if (focusElem) {
                    const hasAutoFocus = focusElem.attributes['ipx-autofocus'];
                    if (hasAutoFocus === '' || hasAutoFocus)  {
                        const inputElement = focusElem.querySelector('input, textarea, select');
                        if (inputElement) {
                            inputElement.focus();
                        } else {
                            focusElem.focus();
                        }
                    }
                }
            }, latency || 10);
        }
    };
}