import { Injectable } from '@angular/core';
import { CaseDetailService } from 'cases/case-view/case-detail.service';

@Injectable()
export class CaseWebLinksTaskProvider {

    constructor(private readonly caseDetailService: CaseDetailService) { }

    noAction = (): void => {
        return;
    };

    private readonly openWebLink = (dataItem: any, event: any): void => {
        if (event.item.url) {
            const linkElement = document.createElement('a');
            linkElement.href = event.item.url;
            linkElement.target = '_blank';
            linkElement.click();
        }
    };

    subscribeCaseWebLinks = (dataItem: any, webLink: any): void => {
        this.caseDetailService.getCaseWebLinks$(dataItem.caseKey).subscribe((results) => {
            results.forEach((group, groupIndex) => {
                if (group.groupName) {
                    const groupTask = {
                        id: 'webLinkGroup' + groupIndex,
                        text: group.groupName,
                        parent: webLink,
                        action: this.noAction,
                        items: []
                    };
                    webLink.menu ? webLink.menu.items.push(groupTask) : webLink.items.push(groupTask);
                    group.links.forEach((t, itemIndex) => {
                        groupTask.items.push({
                            id: 'webLinkItem' + groupIndex + '_' + itemIndex,
                            text: t.linkTitle,
                            parent: groupTask,
                            url: t.url,
                            action: this.openWebLink
                        });
                    });
                } else {
                    group.links.forEach((t, itemIndex) => {
                        if (webLink.menu) {
                            webLink.menu.items.push({
                                id: 'webLinkItem' + groupIndex + '_' + itemIndex,
                                text: t.linkTitle,
                                parent: webLink,
                                url: t.url,
                                action: this.openWebLink
                            });
                        } else {
                            webLink.items.push({
                                id: 'webLinkItem' + groupIndex + '_' + itemIndex,
                                text: t.linkTitle,
                                parent: webLink,
                                url: t.url,
                                action: this.openWebLink
                            });
                        }
                    });
                }
            });
        });
    };
}