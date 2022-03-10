import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';

@Component({
  selector: 'ipx-generate-document-errors',
  templateUrl: './generate-document-errors.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class GenerateDocumentErrorsComponent implements OnInit {
  @Input() errors;
  gridOptions: IpxGridOptions;
  documentName: string;
  constructor(private readonly bsModalRef: BsModalRef) {
  }
  ngOnInit(): void {
    this.gridOptions = this.buildGridOptions();
  }

  onClose(): void {
    this.bsModalRef.hide();
  }

  private readonly buildGridOptions = (): IpxGridOptions => {
    const options: IpxGridOptions = {
      autobind: true,
      reorderable: false,
      gridMessages: {
        noResultsFound: 'grid.messages.noItems',
        performSearch: ''
      },
      read$: () => {
        return of(this.errors).pipe(delay(100));
      },
      columns: this.getColumns()
    };

    return options;
  };

  private readonly getColumns = (): Array<GridColumnDefinition> => {
    return [{
      title: 'documentGeneration.errors.field',
      field: 'field'
    }, {
      title: 'documentGeneration.errors.message',
      field: 'message'
    }];
  };
}
