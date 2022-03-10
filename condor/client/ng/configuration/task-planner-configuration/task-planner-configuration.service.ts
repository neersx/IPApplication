import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { TaskPlannerTabConfigItem } from './task-planner-configuration.model';

@Injectable()
export class TaskPlannerConfigurationService {
    constructor(private readonly http: HttpClient) {
    }
    url = 'api/configuration/taskPlannerConfiguration';

    getProfileTabData(): Observable<Array<TaskPlannerTabConfigItem>> {
        return this.http.get<Array<TaskPlannerTabConfigItem>>(this.url);
    }

    save(tabsData: Array<TaskPlannerTabConfigItem>): Observable<boolean> {
        return this.http.post<boolean>(`${this.url}/save`, tabsData);
    }
}
