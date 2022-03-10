import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import * as _ from 'underscore';

@Injectable()
export class DmsPersistenceService {
    folders$: BehaviorSubject<any> = new BehaviorSubject<any>([]);

    hasPersistedFolders(selectedNode): boolean {
        if (selectedNode.hasChildFolders) {
            const childNodes = selectedNode.childFolders;
            if (childNodes && childNodes.length > 0) {
                this.folders$.next(childNodes);

                return true;
            }
        }

        return false;
    }

}