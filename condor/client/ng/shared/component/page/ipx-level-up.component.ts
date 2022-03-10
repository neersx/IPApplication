// tslint:disable: prefer-object-spread
import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { Transition } from '@uirouter/core';
import * as _ from 'underscore';

@Component({
    selector: 'ipx-level-up-button',
    template: `<a [uiSref]="toState" [uiParams]="stateParams" (click)="levelUp()" class="no-underline">
    <span class="cpa-icon cpa-icon-arrow-circle-nw" tooltip="tooltip"></span>
    </a>`,
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxLevelUpButtonComponent implements OnInit {
    @Input() tooltip: string;
    @Input() toState: string;
    @Input() beforeLevelUp: () => any;
    @Input() additionalStateParams: any;
    stateParams: {};
    constructor(private readonly translate: TranslateService, private readonly $transition: Transition) { }

    ngOnInit(): void {

        const lastFootprint: any = _.last((this.$transition.from() as any).footprints);
        this.toState = this.toState || (lastFootprint ? lastFootprint.from.name : '^');

        this.stateParams = Object.assign({}, lastFootprint ? lastFootprint.fromParams : {}, this.additionalStateParams, { isLevelUp: true });

        if (!this.tooltip) {
            this.translate.get('LevelUp').subscribe((translated: string) => {
                this.tooltip = translated;
            });
        }
    }

    levelUp(): void {
        if (this.beforeLevelUp) {
            this.beforeLevelUp();
        }
        if (this.toState === '^' || this.$transition.to().name.indexOf(this.toState) === 0) {
            // bus.channel('grid.' + vm.gridId).broadcast({
            //     rowId: $stateParams.id,
            //     pageIndex: vm.lastSearch.getPageForId($stateParams.id).page
            // });
        }
    }
}