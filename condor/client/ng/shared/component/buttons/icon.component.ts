import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { BehaviorSubject, Subject } from 'rxjs';

@Component({
    selector: 'ipx-icon',
    templateUrl: './icon.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IconComponent implements OnInit {
    @Input('name') set name(value: string) {
        this.nameValue = value;
        this.resolveIcon();
    }
    @Input() class: string;
    @Input() large?: boolean;
    @Input() circle?: boolean;
    @Input() square?: boolean;
    @Input() document?: boolean;
    nameValue: string;
    iconClass = 'cpa-icon cpa-icon-question-circle';
    ilarge = '';
    mainClass = '';
    additionalClass: string;
    subClass: string;
    mainClass$ = new BehaviorSubject('');
    subClass$ = new BehaviorSubject('');
    additionalClass$ = new BehaviorSubject('');

    resolveIcon = () => {
        if (this.nameValue) {
            this.iconClass = this.nameValue.match(/^glyphicon-/) ? 'glyphicon ' + this.nameValue : 'cpa-icon cpa-icon-' + this.nameValue;
        }
        if (this.large) {
            this.ilarge = ' cpa-icon-lg';
        }

        this.mainClass$.next('cpa-icon-stack' + this.ilarge);
        if (this.circle) {
            this.additionalClass$.next('fa cpa-icon-circle cpa-icon-stack-2x ' + this.class);
            this.subClass$.next(this.iconClass + ' cpa-icon-stack-1x cpa-icon-inverse');
        } else if (this.square) {
            this.additionalClass$.next('fa cpa-icon-square cpa-icon-stack-2x ' + this.class);
            this.subClass$.next(this.iconClass + ' cpa-icon-stack-1x cpa-icon-inverse');
        } else if (this.document) {
            this.additionalClass$.next('fa cpa-icon-file-o cpa-icon-stack-2x ' + this.class);
            this.subClass$.next(this.iconClass + ' cpa-icon-stack-1x ' + this.class);
        } else {
            this.mainClass$.next(this.iconClass + ' ' + this.class + this.ilarge);
        }
    };
    ngOnInit(): void {
        this.resolveIcon();
    }
}
