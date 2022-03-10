import { Injectable } from '@angular/core';
import { queryContextKeyEnum } from 'search/common/search-type-config.provider';
import { BillReversalType, BillSearchPermissions, CaseSearchPermissions, NameSearchPermissions, PriorArtSearchPermissions } from './search-results.data';
@Injectable()
export class SearchResultPermissionsEvaluator {
    isHosted: boolean;
    queryContextKey: queryContextKeyEnum;
    permissions: any;

    initializeContext = (permissions: any, queryContextKey: number, isHosted: boolean): void => {
        this.permissions = permissions;
        this.queryContextKey = queryContextKey;
        this.isHosted = isHosted;
    };

    // tslint:disable-next-line: cyclomatic-complexity
    checkForAtleaseOneTaskMenuPermission = (): boolean => {
        let hasAtleaseOneTaskMenuPermission = false;
        if (!this.permissions) {
            return hasAtleaseOneTaskMenuPermission;
        }

        switch (this.queryContextKey) {
            case queryContextKeyEnum.caseSearch:
                const csp = this.permissions as CaseSearchPermissions;
                if (csp.canOpenWebLink === true) {
                    hasAtleaseOneTaskMenuPermission = true;
                    break;
                }
                if (this.isHosted) {
                    hasAtleaseOneTaskMenuPermission = csp.canMaintainCase === true ||
                        csp.canOpenWorkflowWizard === true ||
                        csp.canOpenDocketingWizard === true ||
                        csp.canMaintainFileTracking === true ||
                        csp.canOpenFirstToFile === true ||
                        csp.canOpenWipRecord === true ||
                        csp.canOpenCopyCase === true ||
                        csp.canRecordTime === true ||
                        csp.canOpenReminders === true ||
                        csp.canCreateAdHocDate === true;
                }
                break;
            case queryContextKeyEnum.nameSearch:
                const nsp = this.permissions as NameSearchPermissions;
                if (this.isHosted) {
                    hasAtleaseOneTaskMenuPermission = nsp.canMaintainNameAttributes === true ||
                        nsp.canMaintainNameNotes === true ||
                        nsp.canMaintainName === true ||
                        nsp.canMaintainOpportunity === true ||
                        nsp.canMaintainContactActivity === true ||
                        nsp.canMaintainAdHocDate === true ||
                        nsp.canAccessDocumentsFromDms === true;
                } else {
                    hasAtleaseOneTaskMenuPermission = nsp.canAccessDocumentsFromDms === true;
                }
                break;
            case queryContextKeyEnum.priorArtSearch:
                const psp = this.permissions as PriorArtSearchPermissions;
                if (this.isHosted) {
                    hasAtleaseOneTaskMenuPermission = psp.canMaintainPriorArt === true;
                }
                break;
            case queryContextKeyEnum.billSearch:
                const bsp = this.permissions as BillSearchPermissions;
                hasAtleaseOneTaskMenuPermission = bsp.canDeleteCreditNote
                    || bsp.canDeleteDebitNote
                    || (this.isHosted && (bsp.canReverseBill !== BillReversalType.ReversalNotAllowed))
                    || this.isHosted && bsp.canCreditBill;
                break;
            default:
                break;
        }

        return hasAtleaseOneTaskMenuPermission;
    };

    showContextMenu = (): boolean => {
        let showTaskMenu = false;
        switch (this.queryContextKey) {
            case queryContextKeyEnum.nameSearch:
            case queryContextKeyEnum.caseSearch:
            case queryContextKeyEnum.priorArtSearch:
            case queryContextKeyEnum.billSearch:
                showTaskMenu = true;
                break;
            default:
                break;
        }

        return showTaskMenu;
    };
}
