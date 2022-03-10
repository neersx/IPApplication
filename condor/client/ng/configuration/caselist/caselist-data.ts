
export type CaseListPermissions = {
    canInsertCaseList: Boolean;
    canUpdateCaseList: Boolean;
    canDeleteCaseList: Boolean;
};

export type CaseListViewData = {
    permissions: CaseListPermissions;
};