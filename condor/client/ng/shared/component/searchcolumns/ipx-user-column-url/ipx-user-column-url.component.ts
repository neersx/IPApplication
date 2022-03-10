import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';

@Component({
    selector: 'ipx-user-column-url',
    templateUrl: './ipx-user-column-url.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxUserColumnUrlComponent implements OnInit {
    @Input() userUrl: string;
    isDisplayName: boolean;
    displayName: string;
    href: string;

    ngOnInit(): void {
        this.checkUrl();
    }

    checkUrl = (): void => {
        if (this.userUrl.indexOf('|') !== -1) {
            this.isDisplayName = true;
            const givenUrl = this.userUrl.match(/\[(.*?)\]/);
            const splitUrl = givenUrl[1].split('|');
            this.displayName = splitUrl[0];
            this.href = splitUrl[1];
        } else {
            this.isDisplayName = false;
        }
    };
}
