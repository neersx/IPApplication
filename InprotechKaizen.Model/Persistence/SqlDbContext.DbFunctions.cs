using System;
using System.Data.Entity;
using System.Data.Entity.Core.Objects;
using System.Data.Entity.Infrastructure;
using System.Linq;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Integration.PtoAccess;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Persistence
{
    public partial class SqlDbContext
    {
        [DbFunction("CodeFirstDatabaseSchema", "fn_GetTranslation")]
        public string GetTranslation(string shortText, string longText, int? translationId, string requestedCulture)
        {
            throw new NotImplementedException();
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_GetCriteriaNo")]
        public int? GetCriteriaNo(int caseId, string purposeCode, string genericParam, DateTime dtToday, int? profileKey)
        {
            throw new NotImplementedException();
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_GetCriteriaNoForName")]
        public int? GetCriteriaNoForName(int nameId, string purposeCode, string genericParam, int? profileKey)
        {
            throw new NotImplementedException();
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_GetDerivedAttnNameNo")]
        public int? GetDerivedAttnNameNo(int? nameId, int? caseId, string nameTypeId)
        {
            throw new NotImplementedException();
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_StripNonAlphaNumerics")]
        public string StripNonAlphanumerics(string text)
        {
            throw new NotImplementedException();
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_ConvertToPctShortFormat")]
        public string ConvertToPctShortFormat(string text)
        {
            throw new NotImplementedException();
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_ConvertIntToString")]
        public static string ConvertIntToString(int number)
        {
            throw new NotImplementedException();
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_appsResolveMapping")]
        public string ResolveMapping(int structureId, short pnFallbackScheme, string inputDescription, string systemCode)
        {
            throw new NotImplementedException();
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_DoesEntryExistForCaseEvent")]
        public bool DoesEntryExistForCaseEvent(int userIdentityId, int caseKey, int eventKey, short cycle)
        {
            throw new NotImplementedException();
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_PermissionsGrantedAll")]
        public IQueryable<PermissionsGrantedAllItem> PermissionsGrantedAll(string objectTable, int? objectIntegerKey, string objectStringKey, DateTime today)
        {
            var intKey = objectIntegerKey.HasValue;
            var strKey = !string.IsNullOrWhiteSpace(objectStringKey);

            var parameters = new[]
            {
                new ObjectParameter("psObjectTable", objectTable),
                intKey ? new ObjectParameter("pnObjectIntegerKey", objectIntegerKey) : new ObjectParameter("pnObjectIntegerKey", typeof(int?)),
                strKey ? new ObjectParameter("psObjectStringKey", objectStringKey) : new ObjectParameter("psObjectStringKey", typeof(string)),
                new ObjectParameter("pdtToday", today)
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<PermissionsGrantedAllItem>($"[{GetType().Name}].[fn_PermissionsGrantedAll](@psObjectTable, @pnObjectIntegerKey, @psObjectStringKey, @pdtToday)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_ValidObjects")]
        public IQueryable<ValidObjectItems> ValidObjects(int? identityKey, string objectTable, DateTime today)
        {
            var intKey = identityKey.HasValue;
            var guid = Guid.NewGuid().ToString("N");
            var parameters = new[]
            {
                intKey ? new ObjectParameter("pnIdentityKey" + guid, identityKey) : new ObjectParameter("pnIdentityKey" + guid, typeof(int?)),
                new ObjectParameter("psObjectTable" + guid, objectTable),
                new ObjectParameter("pdtToday" + guid, today)
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<ValidObjectItems>($"[{GetType().Name}].[fn_ValidObjects](@pnIdentityKey" + guid + ", @psObjectTable" + guid + ", @pdtToday" + guid + ")", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_PermissionsGranted")]
        public IQueryable<PermissionsGrantedItem> PermissionsGranted(int userIdentityId, string objectTable, int? objectIntegerKey, string objectStringKey, DateTime today)
        {
            var intKey = objectIntegerKey.HasValue;
            var strKey = !string.IsNullOrWhiteSpace(objectStringKey);

            var parameters = new[]
            {
                new ObjectParameter("pnIdentityKey", userIdentityId),
                new ObjectParameter("psObjectTable", objectTable),
                intKey ? new ObjectParameter("pnObjectIntegerKey", objectIntegerKey) : new ObjectParameter("pnObjectIntegerKey", typeof(int?)),
                strKey ? new ObjectParameter("psObjectStringKey", objectStringKey) : new ObjectParameter("psObjectStringKey", typeof(string)),
                new ObjectParameter("pdtToday", today)
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<PermissionsGrantedItem>($"[{GetType().Name}].[fn_PermissionsGranted](@pnIdentityKey, @psObjectTable, @pnObjectIntegerKey, @psObjectStringKey, @pdtToday)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_PermissionsForLevel")]
        public IQueryable<PermissionsGrantedItem> PermissionsForLevel(string levelTable, string levelKeys, string objectTable, int? objectIntegerKey, string objectStringKey, DateTime today)
        {
            var intKey = objectIntegerKey.HasValue;
            var strKey = !string.IsNullOrWhiteSpace(objectStringKey);

            var parameters = new[]
            {
                new ObjectParameter("psLevelTable", levelTable),
                new ObjectParameter("psLevelKeys", levelKeys),
                new ObjectParameter("psObjectTable", objectTable),
                intKey ? new ObjectParameter("pnObjectIntegerKey", objectIntegerKey) : new ObjectParameter("pnObjectIntegerKey", typeof(int?)),
                strKey ? new ObjectParameter("psObjectStringKey", objectStringKey) : new ObjectParameter("psObjectStringKey", typeof(string)),
                new ObjectParameter("pdtToday", today)
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<PermissionsGrantedItem>($"[{GetType().Name}].[fn_PermissionsForLevel](@psLevelTable, @psLevelKeys, @psObjectTable, @pnObjectIntegerKey, @psObjectStringKey, @pdtToday)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_PermissionRule")]
        public IQueryable<PermissionsRuleItem> PermissionRule(string objectTable, int? objectIntegerKey, string objectStringKey)
        {
            var intKey = objectIntegerKey.HasValue;
            var strKey = !string.IsNullOrWhiteSpace(objectStringKey);

            var parameters = new[]
            {
                new ObjectParameter("psObjectTable", objectTable),
                intKey ? new ObjectParameter("pnObjectIntegerKey", objectIntegerKey) : new ObjectParameter("pnObjectIntegerKey", typeof(int?)),
                strKey ? new ObjectParameter("psObjectStringKey", objectStringKey) : new ObjectParameter("psObjectStringKey", typeof(string))
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<PermissionsRuleItem>($"[{GetType().Name}].[fn_PermissionRule](@psObjectTable, @pnObjectIntegerKey, @psObjectStringKey)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_GetPermission")]
        public IQueryable<Permissions> GetPermission(string levelTable, int levelKey, string objectTable, int objectIntegerKey, string objectStringKey,
                                                     short? selectPermission, short? mandatoryPermission, short? insertPermission,
                                                     short? updatePermission, short? deletePermission, short? executePermission)
        {
            var guid = Guid.NewGuid().ToString("N");
            var strKey = !string.IsNullOrWhiteSpace(objectStringKey);

            var parameters = new[]
            {
                new ObjectParameter("psLevelTable" + guid, levelTable),
                new ObjectParameter("pnLevelKey" + guid, levelKey),
                new ObjectParameter("psObjectTable" + guid, objectTable),
                new ObjectParameter("pnObjectIntegerKey" + guid, objectIntegerKey),
                strKey ? new ObjectParameter("psObjectStringKey" + guid, objectStringKey) : new ObjectParameter("psObjectStringKey" + guid, typeof(string)),
                selectPermission.HasValue ? new ObjectParameter("pnSelectPermission" + guid, selectPermission) : new ObjectParameter("pnSelectPermission" + guid, typeof(short?)),
                mandatoryPermission.HasValue ? new ObjectParameter("pnMandatoryPermission" + guid, mandatoryPermission) : new ObjectParameter("pnMandatoryPermission" + guid, typeof(short?)),
                insertPermission.HasValue ? new ObjectParameter("pnInsertPermission" + guid, insertPermission) : new ObjectParameter("pnInsertPermission" + guid, typeof(short?)),
                updatePermission.HasValue ? new ObjectParameter("pnUpdatePermission" + guid, updatePermission) : new ObjectParameter("pnUpdatePermission" + guid, typeof(short?)),
                deletePermission.HasValue ? new ObjectParameter("pnDeletePermission" + guid, deletePermission) : new ObjectParameter("pnDeletePermission" + guid, typeof(short?)),
                executePermission.HasValue ? new ObjectParameter("pnExecutePermission" + guid, executePermission) : new ObjectParameter("pnExecutePermission" + guid, typeof(short?))
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<Permissions>($"[{GetType().Name}].[fn_GetPermission](@psLevelTable" + guid + ", @pnLevelKey" + guid + ", @psObjectTable" + guid + ", @pnObjectIntegerKey" + guid + ", @psObjectStringKey" + guid + ", @pnSelectPermission" + guid + ", @pnMandatoryPermission" + guid + ", @pnInsertPermission" + guid + ", @pnUpdatePermission" + guid + ", @pnDeletePermission" + guid + ", @pnExecutePermission" + guid + ")", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_PermissionData")]
        public IQueryable<PermissionsRuleItem> PermissionData(string levelTable, int? levelKey, string objectTable, int? objectIntegerKey, string objectStringKey, DateTime today)
        {
            var guid = Guid.NewGuid().ToString("N");

            var parameters = new[]
            {
                new ObjectParameter("psLevelTable" + guid, levelTable),
                levelKey.HasValue ? new ObjectParameter("pnLevelKey" + guid, levelKey) : new ObjectParameter("pnLevelKey" + guid, typeof(int?)),
                new ObjectParameter("psObjectTable" + guid, objectTable),
                objectIntegerKey.HasValue ? new ObjectParameter("pnObjectIntegerKey" + guid, objectIntegerKey) : new ObjectParameter("pnObjectIntegerKey" + guid, typeof(int?)),
                !string.IsNullOrWhiteSpace(objectStringKey) ? new ObjectParameter("psObjectStringKey" + guid, objectStringKey) : new ObjectParameter("psObjectStringKey" + guid, typeof(string)),
                new ObjectParameter("pdtToday" + guid, today)
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<PermissionsRuleItem>($"[{GetType().Name}].[fn_PermissionData](@psLevelTable" + guid + ", @pnLevelKey" + guid + ", @psObjectTable" + guid + ", @pnObjectIntegerKey" + guid + ", @psObjectStringKey" + guid + ", @pdtToday" + guid + ")", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_GetTopicSecurity")]
        public IQueryable<TopicSecurity> GetTopicSecurity(int userIdentityId, string topicKeys, bool isLegacy, DateTime today)
        {
            var parameters = new[]
            {
                new ObjectParameter("pnUserIdentityId", userIdentityId),
                new ObjectParameter("psTopicKeys", topicKeys),
                new ObjectParameter("pbCalledFromCentura", isLegacy),
                new ObjectParameter("pdtToday", today)
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<TopicSecurity>($"[{GetType().Name}].[fn_GetTopicSecurity](@pnUserIdentityId, @psTopicKeys, @pbCalledFromCentura, @pdtToday)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_appsFilterEligibleCasesForComparison")]
        public IQueryable<EligibleCaseItem> FilterEligibleCasesForComparison(string externalSystemCodes)
        {
            var parameters = new[]
            {
                new ObjectParameter("psExternalSystemCodes", externalSystemCodes)
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            ctx.CommandTimeout = 300;
            return ctx.CreateQuery<EligibleCaseItem>($"[{GetType().Name}].[fn_appsFilterEligibleCasesForComparison](@psExternalSystemCodes)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_appsResolveCriticalEventMappings")]
        public IQueryable<SourceMappedEvents> ResolveEventMappings(string inputDescriptions, string systemCode)
        {
            var parameters = new[]
            {
                new ObjectParameter("psMapDescriptions", inputDescriptions),
                new ObjectParameter("psSystemCode", systemCode)
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<SourceMappedEvents>($"[{GetType().Name}].[fn_appsResolveCriticalEventMappings](@psMapDescriptions,@psSystemCode)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterUserCases")]
        public IQueryable<FilteredUserCase> FilterUserCases(int userId, bool isExternalUser, int? caseKey = null)
        {
            var caseKeyParam = new ObjectParameter("pnCaseKey", typeof(int?));
            caseKeyParam.Value = caseKey;
            var parameters = new[]
            {
                new ObjectParameter("pnUserIdentityId", userId),
                new ObjectParameter("pbIsExternalUser", isExternalUser),
                caseKeyParam
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<FilteredUserCase>($"[{GetType().Name}].[fn_FilterUserCases](@pnUserIdentityId, @pbIsExternalUser,@pnCaseKey)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterUserEvents")]
        public IQueryable<FilteredUserEvent> FilterUserEvents(int userId, string culture, bool isExternalUser, bool isLegacy)
        {
            var hasCulture = !string.IsNullOrWhiteSpace(culture);

            var parameters = new[]
            {
                new ObjectParameter("pnUserIdentityId", userId),
                hasCulture ? new ObjectParameter("psLookupCulture", culture) : new ObjectParameter("psLookupCulture", typeof(string)),
                new ObjectParameter("pbIsExternalUser", isExternalUser),
                new ObjectParameter("pbCalledFromCentura", isLegacy)
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<FilteredUserEvent>($"[{GetType().Name}].[fn_FilterUserEvents](@pnUserIdentityId, @psLookupCulture, @pbIsExternalUser, @pbCalledFromCentura)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterUserInstructionTypes")]
        public IQueryable<FilteredUserInstructionTypes> FilterUserInstructionTypes(int userId, string culture, bool isExternalUser, bool isLegacy)
        {
            var hasCulture = !string.IsNullOrWhiteSpace(culture);

            var parameters = new[]
            {
                new ObjectParameter("pnUserIdentityId", userId),
                hasCulture ? new ObjectParameter("psLookupCulture", culture) : new ObjectParameter("psLookupCulture", typeof(string)),
                new ObjectParameter("pbIsExternalUser", isExternalUser),
                new ObjectParameter("pbCalledFromCentura", isLegacy)
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<FilteredUserInstructionTypes>($"[{GetType().Name}].[fn_FilterUserInstructionTypes](@pnUserIdentityId, @psLookupCulture, @pbIsExternalUser, @pbCalledFromCentura)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterUserTextTypes")]
        public IQueryable<FilteredUserTextType> FilterUserTextTypes(int userId, string culture, bool isExternalUser, bool isLegacy)
        {
            var hasCulture = !string.IsNullOrWhiteSpace(culture);

            var parameters = new[]
            {
                new ObjectParameter("pnUserIdentityId", userId),
                hasCulture ? new ObjectParameter("psLookupCulture", culture) : new ObjectParameter("psLookupCulture", typeof(string)),
                new ObjectParameter("pbIsExternalUser", isExternalUser),
                new ObjectParameter("pbCalledFromCentura", isLegacy)
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<FilteredUserTextType>($"[{GetType().Name}].[fn_FilterUserTextTypes](@pnUserIdentityId, @psLookupCulture, @pbIsExternalUser, @pbCalledFromCentura)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterRowAccessCases")]
        public IQueryable<FilteredRowAccessCase> FilterRowAccessCases(int userId)
        {
            var parameters = new[]
            {
                new ObjectParameter("pnUserIdentityId", userId)
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<FilteredRowAccessCase>($"[{GetType().Name}].[fn_FilterRowAccessCases](@pnUserIdentityId)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_CasesRowSecurity")]
        public IQueryable<FilteredRowSecurityCase> CasesRowSecurity(int userId)
        {
            var parameters = new[]
            {
                new ObjectParameter("pnUserIdentityId", userId)
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<FilteredRowSecurityCase>($"[{GetType().Name}].[fn_CasesRowSecurity](@pnUserIdentityId)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_CasesRowSecurityMultiOffice")]
        public IQueryable<FilteredRowSecurityCaseMultiOffice> CasesRowSecurityMultiOffice(int userId)
        {
            var parameters = new[]
            {
                new ObjectParameter("pnUserIdentityId", userId)
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<FilteredRowSecurityCaseMultiOffice>($"[{GetType().Name}].[fn_CasesRowSecurityMultiOffice](@pnUserIdentityId)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_CasesEthicalWall")]
        public IQueryable<FilteredEthicalWallCase> CasesEthicalWall(int userId)
        {
            var parameters = new[]
            {
                new ObjectParameter("pnUserIdentityId", userId)
            };

            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<FilteredEthicalWallCase>($"[{GetType().Name}].[fn_CasesEthicalWall](@pnUserIdentityId)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_GetCaseDueDates")]
        public IQueryable<CaseDueDate> GetCaseDueDates()
        {
            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<CaseDueDate>($"[{GetType().Name}].[fn_GetCaseDueDates]()");
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterUserViewNames")]
        public IQueryable<FilteredUserViewName> FilterUserViewNames(int userId)
        {
            var parameter = new ObjectParameter("pnUserIdentityId", typeof(int)) { Value = userId };

            return ((IObjectContextAdapter)this).ObjectContext
                                                .CreateQuery<FilteredUserViewName>($"[{GetType().Name}].[fn_FilterUserViewNames](@pnUserIdentityId)", parameter);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_NamesEthicalWall")]
        public IQueryable<FilteredEthicalWallName> NamesEthicalWall(int userId)
        {
            var parameter = new ObjectParameter("pnUserIdentityId", typeof(int)) { Value = userId };

            return ((IObjectContextAdapter)this).ObjectContext
                                                .CreateQuery<FilteredEthicalWallName>($"[{GetType().Name}].[fn_NamesEthicalWall](@pnUserIdentityId)", parameter);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_NamesRowSecurity")]
        public IQueryable<FilteredRowSecurityName> NamesRowSecurity(int userId)
        {
            var parameters = new ObjectParameter("pnUserIdentityId", userId);
            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<FilteredRowSecurityName>($"[{GetType().Name}].[fn_NamesRowSecurity](@pnUserIdentityId)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterUserNameTypes")]
        public IQueryable<FilteredUserNameTypes> FilterUserNameTypes(int userId, string culture, bool isExternalUser, bool isLegacy)
        {
            var hasCulture = !string.IsNullOrWhiteSpace(culture);

            var parameters = new[]
            {
                new ObjectParameter("pnUserIdentityId", userId),
                hasCulture ? new ObjectParameter("psLookupCulture", culture) : new ObjectParameter("psLookupCulture", typeof(string)),
                new ObjectParameter("pbIsExternalUser", isExternalUser),
                new ObjectParameter("pbCalledFromCentura", isLegacy)
            };

            return ((IObjectContextAdapter)this).ObjectContext
                                                .CreateQuery<FilteredUserNameTypes>($"[{GetType().Name}].[fn_FilterUserNameTypes](@pnUserIdentityId, @psLookupCulture, @pbIsExternalUser, @pbCalledFromCentura)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterUserNumberTypes")]
        public IQueryable<FilteredUserNumberTypes> FilterUserNumberTypes(int userId, string culture, bool isExternalUser, bool isLegacy)
        {
            var hasCulture = !string.IsNullOrWhiteSpace(culture);

            var parameters = new[]
            {
                new ObjectParameter("pnUserIdentityId", userId),
                hasCulture ? new ObjectParameter("psLookupCulture", culture) : new ObjectParameter("psLookupCulture", typeof(string)),
                new ObjectParameter("pbIsExternalUser", isExternalUser),
                new ObjectParameter("pbCalledFromCentura", isLegacy)
            };

            return ((IObjectContextAdapter)this).ObjectContext
                                                .CreateQuery<FilteredUserNumberTypes>($"[{GetType().Name}].[fn_FilterUserNumberTypes](@pnUserIdentityId, @psLookupCulture, @pbIsExternalUser, @pbCalledFromCentura)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterUserAliasTypes")]
        public IQueryable<FilteredUserAliasTypes> FilterUserAliasTypes(int userId, string culture, bool isExternalUser, bool isLegacy)
        {
            var hasCulture = !string.IsNullOrWhiteSpace(culture);

            var parameters = new[]
            {
                new ObjectParameter("pnUserIdentityId", userId),
                hasCulture ? new ObjectParameter("psLookupCulture", culture) : new ObjectParameter("psLookupCulture", typeof(string)),
                new ObjectParameter("pbIsExternalUser", isExternalUser),
                new ObjectParameter("pbCalledFromCentura", isLegacy)
            };

            return ((IObjectContextAdapter)this).ObjectContext
                                                .CreateQuery<FilteredUserAliasTypes>($"[{GetType().Name}].[fn_FilterUserAliasTypes](@pnUserIdentityId, @psLookupCulture, @pbIsExternalUser, @pbCalledFromCentura)", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_GetSysActiveSessions")]
        public IQueryable<SysActiveSessions> GetSysActiveSessions()
        {
            var ctx = ((IObjectContextAdapter)this).ObjectContext;
            return ctx.CreateQuery<SysActiveSessions>($"[{GetType().Name}].[fn_GetSysActiveSessions]()");
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_GetCriteriaRows")]
        public IQueryable<CriteriaRows> GetCriteriaRows(string purposeCode, int? caseOffice, string caseType, string psAction, string pnCheckListType, string psProgramID, string pnRateNo, string propertyType, string countryCode, string caseCategory, string subType, string propertyBases, string psRegisteredUsers, int? pnTypeOfMark, int? pnLocalClientFlag, int tableCode, DateTime? pdtDateOfAct, int? pnRuleInUse, int? pnPropertyUnknown, int? pnCountryUnknown, int? pnCategoryUnknown, int? pnSubTypeUnknown, string psNewCaseType, string psNewPropertyType, string psNewCountryCode, string psNewCaseCategory, int? pnRuleType, string psRequestType, int? pnDataSourceType, int? pnDataSourceNameNo, int? pnRenewalStatus, int? pnStatusCode, bool exactMatch, int? pnProfileKey)
        {
            var parameters = new[]
            {
                AddParameter("psPurposeCode", purposeCode),
                AddParameter("pnCaseOfficeID", caseOffice),
                AddParameter("psCaseType", caseType),
                AddParameter("psAction", psAction),
                AddParameter("pnCheckListType", pnCheckListType),
                AddParameter("psProgramID", psProgramID),
                AddParameter("pnRateNo", pnRateNo),
                AddParameter("psPropertyType", propertyType),
                AddParameter("psCountryCode", countryCode),
                AddParameter("psCaseCategory", caseCategory),
                AddParameter("psSubType", subType),
                AddParameter("psBasis", propertyBases),
                AddParameter("psRegisteredUsers", psRegisteredUsers),
                AddParameter("pnTypeOfMark", pnTypeOfMark),
                AddParameter("pnLocalClientFlag", pnLocalClientFlag),
                AddParameter("pnTableCode", tableCode),
                AddParameter("pdtDateOfAct", pdtDateOfAct),
                AddParameter("pnRuleInUse", pnRuleInUse),
                AddParameter("pnPropertyUnknown", pnPropertyUnknown),
                AddParameter("pnCountryUnknown", pnCountryUnknown),
                AddParameter("pnCategoryUnknown", pnCategoryUnknown),
                AddParameter("pnSubTypeUnknown", pnSubTypeUnknown),
                AddParameter("psNewCaseType", psNewCaseType),
                AddParameter("psNewPropertyType", psNewPropertyType),
                AddParameter("psNewCountryCode", psNewCountryCode),
                AddParameter("psNewCaseCategory", psNewCaseCategory),
                AddParameter("pnRuleType", pnRuleType),
                AddParameter("psRequestType", psRequestType),
                AddParameter("pnDataSourceType", pnDataSourceType),
                AddParameter("pnDataSourceNameNo", pnDataSourceNameNo),
                AddParameter("pnRenewalStatus", pnRenewalStatus),
                AddParameter("pnStatusCode", pnStatusCode),
                AddParameter("pbExactMatch", exactMatch),
                AddParameter("pnProfileKey", pnProfileKey)
            };
            return ((IObjectContextAdapter)this).ObjectContext
                                                .CreateQuery<CriteriaRows>($"[{GetType().Name}].[fn_GetCriteriaRows]({string.Join(",", parameters.Select(_ => "@" + _.Name))})", parameters);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_GetBillRuleRows")]
        public IQueryable<BillRuleRow> GetBillRuleRows(BillRuleType? ruleType, string wipCode, int? caseId, int? debtorId, int? entityId,
                                                       int? nameCategoryId, bool isLocalClient, string caseType, string propertyType,
                                                       string caseAction,
                                                       string caseCountry, bool exactMatch = false)
        {
            var parameters = new[]
            {
                AddParameter("pnRuleType", ruleType),
                AddParameter("psWIPCode", wipCode),
                AddParameter("pnCaseId", caseId),
                AddParameter("pnDebtorNo", debtorId),
                AddParameter("pnEntityNo", entityId),
                AddParameter("pnNameCategory", nameCategoryId),
                AddParameter("pnLocalClientFlag", isLocalClient),
                AddParameter("psCaseType", caseType),
                AddParameter("psPropertyType", propertyType),
                AddParameter("psCaseAction", caseAction),
                AddParameter("psCaseCountry", caseCountry),
                AddParameter("pbExactMatch", exactMatch)
            };

            return ((IObjectContextAdapter)this).ObjectContext
                                                .CreateQuery<BillRuleRow>($"[{GetType().Name}].[fn_GetBillRuleRows]({string.Join(",", parameters.Select(_ => "@" + _.Name))})", parameters);
        }

        ObjectParameter AddParameter<T>(string parameter, T value)
        {
            return value != null ? new ObjectParameter(parameter, value) : new ObjectParameter(parameter, typeof(T));
        }
    }

    public static class DbFuncs
    {
        [DbFunction("CodeFirstDatabaseSchema", "fn_GetTranslation")]
        public static string GetTranslation(string shortText, string longText, int? translationId, string requestedCulture)
        {
            return !string.IsNullOrEmpty(longText) ? longText : shortText;
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_GetCriteriaNo")]
        public static int? GetCriteriaNo(int caseId, string purposeCode, string genericParam, DateTime dtToday, int? profileKey)
        {
            return null;
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_GetCriteriaNoForName")]
        public static int? GetCriteriaNoForName(int nameId, string purposeCode, string genericParam, int? profileKey)
        {
            return null;
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_GetDerivedAttnNameNo")]
        public static int? GetDerivedAttnNameNo(int? nameId, int? caseId, string nameTypeId)
        {
            return null;
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_StripNonAlphaNumerics")]
        public static string StripNonAlphanumerics(string text)
        {
            return text;
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_ConvertToPctShortFormat")]
        public static string ConvertToPctShortFormat(string text)
        {
            return text;
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_ConvertIntToString")]
        public static string ConvertIntToString(int number)
        {
            return number.ToString().PadLeft(11, ' ');
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_appsResolveMapping")]
        public static string ResolveMapping(int structureId, short fallbackEncodingSchemeId, string inputDescription, string systemCode)
        {
            return inputDescription;
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_DoesEntryExistForCaseEvent")]
        public static bool DoesEntryExistForCaseEvent(int userIdentityId, int caseKey, int eventKey, short cycle)
        {
            return true;
        }

        [DbFunction("Edm", "AddMinutes")]
        public static DateTime? AddMinutes(DateTime? timeValue, int? addValue)
        {
            return timeValue?.Add(new TimeSpan(0, addValue.GetValueOrDefault(), 0));
        }

        [DbFunction("Edm", "TruncateTime")]
        public static DateTime? TruncateTime(DateTime? dateTimeValue)
        {
            return dateTimeValue.GetValueOrDefault().Date;
        }

        [DbFunction("Edm", "DiffDays")]
        public static int? DiffDays(DateTime? dateTimeValue1, DateTime? dateTimeValue2)
        {
            return (dateTimeValue2.GetValueOrDefault() - dateTimeValue1.GetValueOrDefault()).Days;
        }

        public static IQueryable<PermissionsGrantedAllItem> PermissionsGrantedAll(this IDbContext dbContext, string objectTable, int? objectIntegerKey, string objectStringKey, DateTime today)
        {
            var ctx = dbContext as SqlDbContext;

            return ctx == null
                ? FromInMemoryContext<PermissionsGrantedAllItem>(dbContext)
                : ctx.PermissionsGrantedAll(objectTable, objectIntegerKey, objectStringKey, today);
        }

        public static IQueryable<ValidObjectItems> ValidObjects(this IDbContext dbContext, string objectTable, DateTime today, int? identityKey = null)
        {
            var ctx = dbContext as SqlDbContext;

            return ctx == null
                ? FromInMemoryContext<ValidObjectItems>(dbContext)
                : ctx.ValidObjects(identityKey, objectTable, today);
        }

        public static IQueryable<PermissionsGrantedItem> PermissionsGranted(this IDbContext dbContext, int userIdentityId, string objectTable, int? objectIntegerKey, string objectStringKey, DateTime today)
        {
            var ctx = dbContext as SqlDbContext;

            return ctx == null
                ? FromInMemoryContext<PermissionsGrantedItem>(dbContext)
                : ctx.PermissionsGranted(userIdentityId, objectTable, objectIntegerKey, objectStringKey, today);
        }

        public static IQueryable<PermissionsGrantedItem> PermissionsForLevel(this IDbContext dbContext, string levelTable, string levelKeys, string objectTable, int? objectIntegerKey, string objectStringKey, DateTime today)
        {
            var ctx = dbContext as SqlDbContext;

            return ctx == null
                ? FromInMemoryContext<PermissionsGrantedItem>(dbContext)
                : ctx.PermissionsForLevel(levelTable, levelKeys, objectTable, objectIntegerKey, objectStringKey, today);
        }

        public static IQueryable<PermissionsRuleItem> PermissionRule(this IDbContext dbContext, string objectTable, int? objectIntegerKey, string objectStringKey)
        {
            var ctx = dbContext as SqlDbContext;

            return ctx == null
                ? FromInMemoryContext<PermissionsRuleItem>(dbContext)
                : ctx.PermissionRule(objectTable, objectIntegerKey, objectStringKey);
        }

        public static IQueryable<PermissionsRuleItem> PermissionData(this IDbContext dbContext, string levelTable, int? levelKey, string objectTable, int? objectIntegerKey, string objectStringKey, DateTime today)
        {
            var ctx = dbContext as SqlDbContext;

            return ctx == null
                ? FromInMemoryContext<PermissionsRuleItem>(dbContext)
                : ctx.PermissionData(levelTable, levelKey, objectTable, objectIntegerKey, objectStringKey, today);
        }

        public static IQueryable<Permissions> GetPermission(this IDbContext dbContext, string levelTable, int levelKey, string objectTable, int objectIntegerKey,
                                                            string objectStringKey, short? selectPermission, short? mandatoryPermission,
                                                            short? insertPermission, short? updatePermission, short? deletePermission, short? executePermission)
        {
            var ctx = dbContext as SqlDbContext;

            return ctx == null
                ? FromInMemoryContext<FakePermissionsSet>(dbContext).Where(fp => fp.ObjectIntegerKey == objectIntegerKey
                                                                                 && fp.ObjectTable == objectTable
                                                                                 && fp.LevelTable == levelTable
                                                                                 && fp.LevelKey == levelKey
                                                                                 && fp.ExecutePermission == executePermission
                                                                                 && fp.InsertPermission == insertPermission
                                                                                 && fp.UpdatePermission == updatePermission
                                                                                 && fp.DeletePermission == deletePermission
                                                                                 && fp.SelectPermission == selectPermission
                                                                                 && fp.MandatoryPermission == mandatoryPermission)
                                                                    .Select(p => new Permissions
                                                                    {
                                                                        GrantPermission = p.GrantPermission,
                                                                        DenyPermission = p.DenyPermission
                                                                    })
                : ctx.GetPermission(levelTable, levelKey, objectTable, objectIntegerKey, objectStringKey,
                                    selectPermission, mandatoryPermission, insertPermission,
                                    updatePermission, deletePermission, executePermission);
        }

        public static IQueryable<TopicSecurity> GetTopicSecurity(this IDbContext dbContext, int userIdentityId, string topicKeys, bool isLegacy, DateTime today)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<TopicSecurity>(dbContext)
                : ctx.GetTopicSecurity(userIdentityId, topicKeys, isLegacy, today);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_appsFilterEligibleCasesForComparison")]
        public static IQueryable<EligibleCaseItem> FilterEligibleCasesForComparison(this IDbContext dbContext, string externalSystemCodes)
        {
            var ctx = dbContext as SqlDbContext;

            return ctx == null
                ? FromInMemoryContext<EligibleCaseItem>(dbContext)
                : ctx.FilterEligibleCasesForComparison(externalSystemCodes);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_appsResolveCriticalEventMappings")]
        public static IQueryable<SourceMappedEvents> ResolveEventMappings(this IDbContext dbContext, string inputDescriptions, string systemCode)
        {
            var ctx = dbContext as SqlDbContext;

            return ctx == null
                ? FromInMemoryContext<SourceMappedEvents>(dbContext)
                : ctx.ResolveEventMappings(inputDescriptions, systemCode);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterUserCases")]
        public static IQueryable<FilteredUserCase> FilterUserCases(this IDbContext dbContext, int userId, bool isExternalUser, int? caseKey = null)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<FilteredUserCase>(dbContext)
                : ctx.FilterUserCases(userId, isExternalUser, caseKey);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterUserEvents")]
        public static IQueryable<FilteredUserEvent> FilterUserEvents(this IDbContext dbContext, int userId, string culture, bool isExternalUser)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<FilteredUserEvent>(dbContext)
                : ctx.FilterUserEvents(userId, culture, isExternalUser, false);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterUserInstructionTypes")]
        public static IQueryable<FilteredUserInstructionTypes> FilterUserInstructionTypes(this IDbContext dbContext, int userId, string culture, bool isExternalUser)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<FilteredUserInstructionTypes>(dbContext)
                : ctx.FilterUserInstructionTypes(userId, culture, isExternalUser, false);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterRowAccessCases")]
        public static IQueryable<FilteredRowAccessCase> FilterRowAccessCases(this IDbContext dbContext, int userId)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<FilteredRowAccessCase>(dbContext)
                : ctx.FilterRowAccessCases(userId);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_CasesRowSecurity")]
        public static IQueryable<FilteredRowSecurityCase> CasesRowSecurity(this IDbContext dbContext, int userId)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<FilteredRowSecurityCase>(dbContext)
                : ctx.CasesRowSecurity(userId);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_CasesRowSecurityMultiOffice")]
        public static IQueryable<FilteredRowSecurityCaseMultiOffice> CasesRowSecurityMultiOffice(this IDbContext dbContext, int userId)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<FilteredRowSecurityCaseMultiOffice>(dbContext)
                : ctx.CasesRowSecurityMultiOffice(userId);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_CasesEthicalWall")]
        public static IQueryable<FilteredEthicalWallCase> CasesEthicalWall(this IDbContext dbContext, int userId)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<FilteredEthicalWallCase>(dbContext)
                : ctx.CasesEthicalWall(userId);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_GetCaseDueDates")]
        public static IQueryable<CaseDueDate> GetCaseDueDates(this IDbContext dbContext)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<CaseDueDate>(dbContext)
                : ctx.GetCaseDueDates();
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterUserViewNames")]
        public static IQueryable<FilteredUserViewName> FilterUserViewNames(this IDbContext dbContext, int userId)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<FilteredUserViewName>(dbContext)
                : ctx.FilterUserViewNames(userId);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_NamesEthicalWall")]
        public static IQueryable<FilteredEthicalWallName> NamesEthicalWall(this IDbContext dbContext, int userId)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<FilteredEthicalWallName>(dbContext)
                : ctx.NamesEthicalWall(userId);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_NamesRowSecurity")]
        public static IQueryable<FilteredRowSecurityName> NamesRowSecurity(this IDbContext dbContext, int userId)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<FilteredRowSecurityName>(dbContext)
                : ctx.NamesRowSecurity(userId);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterUserNameTypes")]
        public static IQueryable<FilteredUserNameTypes> FilterUserNameTypes(this IDbContext dbContext, int userId, string culture, bool isExternalUser, bool isLegacy)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<FilteredUserNameTypes>(dbContext)
                : ctx.FilterUserNameTypes(userId, culture, isExternalUser, isLegacy);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterUserNumberTypes")]
        public static IQueryable<FilteredUserNumberTypes> FilterUserNumberTypes(this IDbContext dbContext, int userId, string culture, bool isExternalUser, bool isLegacy)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<FilteredUserNumberTypes>(dbContext)
                : ctx.FilterUserNumberTypes(userId, culture, isExternalUser, isLegacy);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fnw_GetScreenControlNameTypes")]
        public static IQueryable<string> GetScreenControlNameTypes(this IDbContext dbContext, int userId, int caseKey, string screenControlProgram)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<string>(dbContext)
                : ctx.GetScreenControlNameTypes(userId, caseKey, screenControlProgram);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterUserAliasTypes")]
        public static IQueryable<FilteredUserAliasTypes> FilterUserAliasTypes(this IDbContext dbContext, int userId, string culture, bool isExternalUser, bool isLegacy)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<FilteredUserAliasTypes>(dbContext)
                : ctx.FilterUserAliasTypes(userId, culture, isExternalUser, isLegacy);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_FilterUserTextTypes")]
        public static IQueryable<FilteredUserTextType> FilterUserTextTypes(this IDbContext dbContext, int userId, string culture, bool isExternalUser, bool isLegacy)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<FilteredUserTextType>(dbContext)
                : ctx.FilterUserTextTypes(userId, culture, isExternalUser, isLegacy);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_GetCriteriaRows")]
        public static IQueryable<CriteriaRows> GetCriteriaRows(this IDbContext dbContext, string purposeCode, int? caseOffice, string caseType, string propertyType, string countryCode, string caseCategory, string subType, string propertyBases, int tableCode, bool exactMatch = false)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<CriteriaRows>(dbContext)
                : ctx.GetCriteriaRows(purposeCode, caseOffice, caseType, null, null, null, null, propertyType, countryCode, caseCategory, subType, propertyBases, null, null, null, tableCode, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, exactMatch, null);
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_GetSysActiveSessions")]
        public static IQueryable<SysActiveSessions> GetSysActiveSessions(this IDbContext dbContext)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<SysActiveSessions>(dbContext)
                : ctx.GetSysActiveSessions();
        }

        [DbFunction("CodeFirstDatabaseSchema", "fn_GetBillRuleRows")]
        public static IQueryable<BillRuleRow> GetBillRuleRows(this IDbContext dbContext, BillRuleType? ruleType, string wipCode, int? caseId, int? debtorId, int? entityId,
                                                              int? nameCategoryId, bool isLocalClient, string caseType, string propertyType,
                                                              string caseAction,
                                                              string caseCountry, bool exactMatch = false)
        {
            var ctx = dbContext as SqlDbContext;
            return ctx == null
                ? FromInMemoryContext<BillRuleRow>(dbContext)
                : ctx.GetBillRuleRows(ruleType, wipCode, caseId, debtorId, entityId, nameCategoryId, isLocalClient, caseType, propertyType, caseAction, caseCountry, exactMatch);
        }

        static IQueryable<T> FromInMemoryContext<T>(IDbContext dbContext) where T : class
        {
            return dbContext.Set<T>().AsQueryable();
        }
    }
}