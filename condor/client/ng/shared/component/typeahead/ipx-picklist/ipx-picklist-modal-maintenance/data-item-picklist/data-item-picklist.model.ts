export class DataItem {
    key?: number;
    code?: string;
    value?: string;
    itemGroups?: any = [];
    entryPointUsage?: any;
    isSqlStatement?: Boolean;
    returnsImage?: Boolean;
    useSourceFile?: Boolean;
    notes?: string;
    sql?: Sql;
}

export class Sql {
    sqlStatement?: string;
    storedProcedure?: string;
}