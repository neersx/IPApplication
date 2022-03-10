import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { caseViewTopicTitles } from 'cases/case-view/case-view-topic-titles';
import { ScreenDesignerService } from 'configuration/rules/screen-designer/screen-designer.service';
import { map } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { Topic } from 'shared/component/topics/ipx-topic.model';

@Component({
    selector: 'app-screen-designer-sections',
    templateUrl: './screen-designer-sections.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class ScreenDesignerSectionsComponent implements OnInit {
    topic: Topic;
    gridoptions: IpxGridOptions;

    constructor(private readonly service: ScreenDesignerService, private readonly translateService: TranslateService, private readonly cdRef: ChangeDetectorRef) {
    }

    ngOnInit(): void {
        this.gridoptions = this.buildGridOptions();
    }

    private readonly buildGridOptions = (): IpxGridOptions => {
        return {
            sortable: false,
            pageable: false,
            selectable: {
                mode: 'single'
            },
            read$: () => this.service.getCriteriaSections$(this.topic.params.viewData.criteriaData.id).pipe(map((res: Array<any>) => {
                const keys = Object.keys(caseViewTopicTitles);
                res.forEach(e => {
                    if (!e.title) {
                        e.title = keys.indexOf(e.name) !== -1 ? this.translateService.instant(caseViewTopicTitles[e.name]) : e.name;
                    }
                });

                return res;
            })),
            columns: [{
                field: 'title', title: 'screenDesignerCases.criteriaMaintenance.criteriaSections.sectionColumn', sortable: false
            }]
        };
    };
}