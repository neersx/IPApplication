import { ChangeDetectionStrategy, Component, ViewChild } from '@angular/core';
import { PriorArtService } from 'cases/prior-art/priorart.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { TypeaheadConfig } from 'shared/component/typeahead/ipx-typeahead/typeahead.config.provider';

@Component({
    selector: 'update-priorart-status',
    templateUrl: './update-priorart-status.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class UpdatePriorArtStatusComponent {
    success$ = new Subject<boolean>();
    priorArtStatus?: any;
    caseKeys: Array<number>;
    sourceDocumentId: number;
    clearStatus = false;
    isSelectAll: boolean;
    exceptCaseKeys: Array<number>;
    queryParams: GridQueryParameters;

    constructor(private readonly selfModalRef: BsModalRef, private readonly service: PriorArtService) { }

    save(): void {
        this.service.updatePriorArtStatus$({caseKeys: this.caseKeys, sourceDocumentId: this.sourceDocumentId, status: this.clearStatus ? null : this.priorArtStatus.key, clearStatus: this.clearStatus, isSelectAll: this.isSelectAll, exceptCaseKeys: this.exceptCaseKeys}, this.queryParams).subscribe(() => {
            this.success$.next(true);
            this.selfModalRef.hide();
        });
    }

    cancel(): void {
        this.selfModalRef.hide();
    }

    click(): void {
        if (this.clearStatus) {
            this.priorArtStatus = null;
        }
    }
}
