import { queryContextKeyEnum } from 'search/common/search-type-config.provider';
import { SearchResultPermissionsEvaluator } from './search-result-permissions-evaluator';

describe('SearchResultPermissionsEvaluator', () => {

  let service: SearchResultPermissionsEvaluator;

  beforeEach(() => {
    service = new SearchResultPermissionsEvaluator();
  });

  it('should load task permissions configuration service', () => {
    expect(service).toBeTruthy();
  });

  it('validate initializeContext', () => {
    const permissions = {
      canUpdateEventsInBulk: true,
      canMaintainCase: true,
      canOpenWorkflowWizard: true
    };
    service.initializeContext(permissions, queryContextKeyEnum.caseSearch, true);
    expect(service.queryContextKey).toEqual(queryContextKeyEnum.caseSearch);
    expect(service.permissions).toEqual(permissions);
    expect(service.isHosted).toBeTruthy();
  });

  describe('checkForAtleaseOneTaskMenuPermission method', () => {

    it('validate checkForAtleaseOneTaskMenuPermission with CaseSearch and permission', () => {
      service.isHosted = true;
      service.queryContextKey = queryContextKeyEnum.caseSearch;
      service.permissions = {
        canUpdateEventsInBulk: true,
        canMaintainCase: true,
        canOpenWorkflowWizard: true
      };
      const result = service.checkForAtleaseOneTaskMenuPermission();
      expect(result).toBeTruthy();
    });

    it('validate checkForAtleaseOneTaskMenuPermission with CaseSearch and no permission', () => {
      service.isHosted = true;
      service.queryContextKey = queryContextKeyEnum.caseSearch;
      service.permissions = {
        canUpdateEventsInBulk: false,
        canMaintainCase: false,
        canOpenWorkflowWizard: false
      };
      const result = service.checkForAtleaseOneTaskMenuPermission();
      expect(result).toBeFalsy();
    });

    it('validate checkForAtleaseOneTaskMenuPermission with nameSearch and permission', () => {
      service.isHosted = true;
      service.queryContextKey = queryContextKeyEnum.nameSearch;
      service.permissions = {
        canMaintainNameNotes: true,
        canMaintainName: true
      };
      const result = service.checkForAtleaseOneTaskMenuPermission();
      expect(result).toBeTruthy();
    });

    it('validate checkForAtleaseOneTaskMenuPermission with nameSearch and no permission', () => {
      service.isHosted = true;
      service.queryContextKey = queryContextKeyEnum.nameSearch;
      service.permissions = {
        canMaintainNameNotes: false,
        canMaintainName: false
      };
      const result = service.checkForAtleaseOneTaskMenuPermission();
      expect(result).toBeFalsy();
    });

    it('validate checkForAtleaseOneTaskMenuPermission with priorArtSearch and permission', () => {
      service.isHosted = true;
      service.queryContextKey = queryContextKeyEnum.priorArtSearch;
      service.permissions = {
        canMaintainPriorArt: true
      };
      const result = service.checkForAtleaseOneTaskMenuPermission();
      expect(result).toBeTruthy();
    });

    it('validate checkForAtleaseOneTaskMenuPermission with priorArtSearch and no permission', () => {
      service.isHosted = true;
      service.queryContextKey = queryContextKeyEnum.priorArtSearch;
      service.permissions = {
        canMaintainPriorArt: false
      };
      const result = service.checkForAtleaseOneTaskMenuPermission();
      expect(result).toBeFalsy();
    });

    it('validate checkForAtleaseOneTaskMenuPermission with bill search and permission', () => {
      service.queryContextKey = queryContextKeyEnum.billSearch;
      service.permissions = {
        canDeleteDebitNote: true,
        canDeleteCreditNote: true
      };
      const result = service.checkForAtleaseOneTaskMenuPermission();
      expect(result).toBeTruthy();
    });

    it('validate checkForAtleaseOneTaskMenuPermission with bill search and no permission', () => {
      service.queryContextKey = queryContextKeyEnum.billSearch;
      service.permissions = {
        canMaintainDebitNote: false
      };
      const result = service.checkForAtleaseOneTaskMenuPermission();
      expect(result).toBeFalsy();
    });

    it('validate showContextMenu without query context', () => {
      service.queryContextKey = null;
      const result = service.showContextMenu();
      expect(result).toBeFalsy();
    });

    it('validate showContextMenu with caseSearch query context', () => {
      service.queryContextKey = queryContextKeyEnum.caseSearch;
      const result = service.showContextMenu();
      expect(result).toBeTruthy();
    });

    it('validate showContextMenu with billSearch query context', () => {
      service.queryContextKey = queryContextKeyEnum.billSearch;
      const result = service.showContextMenu();
      expect(result).toBeTruthy();
    });

  });

});
