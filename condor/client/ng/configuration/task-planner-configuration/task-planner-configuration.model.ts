export class TaskPlannerTabConfigItem {
    id?: number;
    profile: ProfileData;
    tab1: QueryData;
    tab2: QueryData;
    tab3: QueryData;
    isDeleted: boolean;
}

export class QueryData {
    key: number;
    searchName: string;
}

export class ProfileData {
    key: number;
    code: number;
    name: string;
}