import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { ModalService } from 'ajs-upgraded-providers/modal-service.provider';
import { FeatureDetection } from 'core/feature-detection';

@Component({
    selector: 'ipx-ie-only-url',
    templateUrl: './ipx-ie-only-url.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxIeOnlyUrlComponent implements OnInit {
    @Input() url: string;
    @Input() text: string;
    isIe = false;
    inproVersion16 = false;

    constructor(
        private readonly featureDetection: FeatureDetection,
        private readonly modalService: ModalService
    ) { }

    ngOnInit(): void {
        this.isIe = this.featureDetection.isIe();
        this.featureDetection.hasSpecificRelease$(16).subscribe(_ => {
            this.inproVersion16 = _;
        });
    }

    showIeRequired = () => {
        this.modalService.openModal({
            id: 'ieRequired',
            controllerAs: 'vm',
            url: this.featureDetection.getAbsoluteUrl(this.url)
        });
    };

    linkText = () => this.text;
}
