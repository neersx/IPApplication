import { Directive, HostListener, Input, OnDestroy, OnInit } from '@angular/core';
import { TransitionService } from '@uirouter/core';

@Directive({
    selector: '[ipxConfirmBeforeRouteChange]'
})
export class IpxConfirmBeforeRouteChangeDirective implements OnInit, OnDestroy {
    deregister;
    @Input('ipxConfirmBeforeRouteChange') isPageDirty = null;
    @Input() confirmMessage = 'Changes you made may not be saved.';

    @HostListener('window:beforeunload', ['$event']) beforeUnload($event): void {
        if (this.isPageDirty && this.isPageDirty()) {
            $event.returnValue = this.confirmMessage;
        }
    }
    constructor(public $trans: TransitionService) { }

    ngOnInit(): void {
        this.deregister = this.$trans.onFinish(null, () => this.canRouteChange());
    }

    canRouteChange(): any {
        if (this.isPageDirty && this.isPageDirty()) {
            return window.confirm(this.confirmMessage);
        }

        return;
    }

    ngOnDestroy(): void {
        if (this.deregister) {
            this.deregister();
        }
    }
}