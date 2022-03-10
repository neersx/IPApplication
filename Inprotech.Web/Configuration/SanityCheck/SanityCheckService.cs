using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.DataValidation;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.ValidCombinations;
using Newtonsoft.Json;
using CaseCategory = InprotechKaizen.Model.Cases.CaseCategory;
using CaseType = InprotechKaizen.Model.Cases.CaseType;
using Characteristic = InprotechKaizen.Model.StandingInstructions.Characteristic;
using Event = InprotechKaizen.Model.Cases.Events;
using InstructionType = InprotechKaizen.Model.StandingInstructions.InstructionType;
using Name = InprotechKaizen.Model.Names;
using Office = InprotechKaizen.Model.Cases.Office;
using PropertyType = InprotechKaizen.Model.Cases.PropertyType;
using SubType = InprotechKaizen.Model.Cases.SubType;

namespace Inprotech.Web.Configuration.SanityCheck
{
    public interface ISanityCheckService
    {
        Task<IEnumerable<dynamic>> GetCaseValidationRules(SanityCheckCaseViewModel filters, CommonQueryParameters param = null);

        Task<CaseSanityCheckRuleModel> GetCaseValidationRule(int id);
        Task<IEnumerable<dynamic>> GetNameValidationRules(SanityCheckNameViewModel filters, CommonQueryParameters param = null);

        Task<NameSanityCheckRuleModel> GetNameValidationRule(int id);
    }

    public static class DataValidationQueryable
    {
        public static IQueryable<DataValidation> CaseRules(this IQueryable<DataValidation> query)
        {
            return query.Where(_ => _.FunctionalArea == KnownFunctionalArea.Case);
        }

        public static IQueryable<DataValidation> NameRules(this IQueryable<DataValidation> query)
        {
            return query.Where(_ => _.FunctionalArea == KnownFunctionalArea.Name);
        }

        public static IQueryable<DataValidation> WithRuleOverviewDetails(this IQueryable<DataValidation> query, RuleOverviewModel data, string culture)
        {
            var displayMessage = data?.DisplayMessage?.ToUpper();
            var ruleDescription = data?.RuleDescription?.ToUpper();
            var notes = data?.Notes?.ToUpper();

            return query.Where(r => (!data.InUse.HasValue || r.InUseFlag == data.InUse)
                                    && (!data.Deferred.HasValue || r.DeferredFlag == data.Deferred)
                                    && (!data.InformationOnly.HasValue || r.IsWarning == data.InformationOnly)
                                    && (!data.MayBypassError.HasValue || r.CanOverrideRoleId == data.MayBypassError)
                                    && (!data.SanityCheckSql.HasValue || r.ItemId == data.SanityCheckSql)
                                    && (string.IsNullOrEmpty(data.DisplayMessage) || DbFuncs.GetTranslation(r.DisplayMessage, null, r.DisplayMessageTid, culture).ToUpper().Contains(displayMessage))
                                    && (string.IsNullOrEmpty(data.Notes) || DbFuncs.GetTranslation(r.Notes, null, r.NotesTid, culture).ToUpper().Contains(notes))
                                    && (string.IsNullOrEmpty(data.RuleDescription) || DbFuncs.GetTranslation(r.RuleDescription, null, r.RuleDescriptionTid, culture).ToUpper().Contains(ruleDescription)));
        }

        public static IQueryable<DataValidation> WithNameDetails(this IQueryable<DataValidation> query, CaseNameModel filters)
        {
            return query.Where(r => (string.IsNullOrEmpty(filters.NameType) || r.NameType == filters.NameType)
                                    && (!filters.Name.HasValue || r.NameId == filters.Name)
                                    && (!filters.NameGroup.HasValue || r.FamilyNo == filters.NameGroup));
        }

        public static IQueryable<DataValidation> WithStandingInstructionDetails(this IQueryable<DataValidation> query, StandingInstructionModel instructionFilters)
        {
            return query.Where(r => (string.IsNullOrEmpty(instructionFilters.InstructionType) || r.InstructionType == instructionFilters.InstructionType)
                                    && (!instructionFilters.Characteristics.HasValue || r.FlagNumber == instructionFilters.Characteristics));
        }

        public static IQueryable<DataValidation> WithEventDetails(this IQueryable<DataValidation> query, EventModel eventFilters)
        {
            var eventDateFlags = eventFilters.GetEventDateFlags();
            var eventFlagIsEmpty = eventDateFlags.Length == 0;

            return query.Where(r => (!eventFilters.EventNo.HasValue || r.EventNo == eventFilters.EventNo)
                                    && (eventFlagIsEmpty || eventDateFlags.Contains((short)r.Eventdateflag)));
        }

        public static IQueryable<DataValidation> WithOtherDetails(this IQueryable<DataValidation> query, OtherModel filters)
        {
            return query.Where(r => !filters.TableCode.HasValue || r.ColumnName == filters.TableCode);
        }

        public static IQueryable<dynamic> SelectCaseSearchData(this IQueryable<CaseSanityCheckRuleModel> data, string culture)
        {
            return data.Select(_ => new
            {
                _.DataValidation.Id,
                _.DataValidation.RuleDescription,
                InUse = _.DataValidation.InUseFlag,
                Deferred = _.DataValidation.DeferredFlag,
                Informational = _.DataValidation.IsWarning,

                CaseOffice = _.CaseDetails.Office != null ? _.CaseDetails.Office.Value : null,
                CaseType = _.CaseDetails.CaseType != null ? _.CaseDetails.CaseType.Value : null,
                Jurisdiction = _.CaseDetails.Jurisdiction != null ? _.CaseDetails.Jurisdiction.Value : null,
                PropertyType = _.CaseDetails.PropertyType != null ? _.CaseDetails.PropertyType.Value : null,
                CaseCategory = _.CaseDetails.Category != null ? _.CaseDetails.Category.Value : null,
                SubType = _.CaseDetails.SubType != null ? _.CaseDetails.SubType.Value : null,
                Basis = _.CaseDetails.Basis != null ? _.CaseDetails.Basis.Value : null,

                ExcludeSubType = _.DataValidation.NotSubtype,
                ExcludeCaseType = _.DataValidation.NotCaseType,
                ExcludeJurisdiction = _.DataValidation.NotCountryCode,
                ExcludePropertyType = _.DataValidation.NotPropertyType,
                ExcludeCaseCategory = _.DataValidation.NotCaseCategory,
                ExcludeBasis = _.DataValidation.NotBasis,

                Pending = (_.DataValidation.StatusFlag & 1) == 1,
                Registered = (_.DataValidation.StatusFlag & 2) == 2,
                Dead = _.DataValidation.StatusFlag == 0
            });
        }

        public static IQueryable<DataValidation> FilterByNameCharacteristics(this IQueryable<DataValidation> query, SanityCheckNameViewModel filters)
        {
            var f = filters.NameCharacteristics;
            var eType = f.EntityType;

            return query.Where(d =>
                                   (!f.Category.HasValue || d.Category == f.Category)
                                   && (string.IsNullOrEmpty(f.Jurisdiction) || d.CountryCode == f.Jurisdiction)
                                   && (!eType.IsOrganisation || d.UsedasFlag.HasValue && (d.UsedasFlag & NameUsedAs.Individual) != NameUsedAs.Individual)
                                   && (!eType.IsIndividual || (d.UsedasFlag & NameUsedAs.Individual) == NameUsedAs.Individual)
                                   && (!eType.IsStaff || (d.UsedasFlag & NameUsedAs.StaffMember) == NameUsedAs.StaffMember)
                                   && (!eType.IsClientOnly || (d.UsedasFlag & NameUsedAs.Client) == NameUsedAs.Client)
                                   && (!f.IsSupplierOnly || d.SupplierFlag == true)
                                   && (!f.IsLocal.HasValue || d.LocalclientFlag == f.IsLocal)
                                   && (!f.NameGroup.HasValue || d.FamilyNo == f.NameGroup)
                                   && (!f.Name.HasValue || d.NameId == f.Name)
                              );
        }

        public static IQueryable<SanityCheckService.NameSanityCheckResult> SelectNameSearchData(this IQueryable<NameSanityCheckRuleIntermediate> data, string culture)
        {
            return data.Select(d => new SanityCheckService.NameSanityCheckResult
            {
                Id = d.DataValidation.Id,
                RuleDescription = DbFuncs.GetTranslation(d.DataValidation.RuleDescription, null, d.DataValidation.RuleDescriptionTid, culture),
                InUse = d.DataValidation.InUseFlag,
                Deferred = d.DataValidation.DeferredFlag,
                Informational = d.DataValidation.IsWarning,
                UsedAs = d.DataValidation.UsedasFlag,
                Supplier = d.DataValidation.SupplierFlag ?? false,
                LocalClient = d.DataValidation.LocalclientFlag,
                Jurisdiction = d.Country == null ? null : d.Country.Value,
                NameGroup = d.NameGroup == null ? null : d.NameGroup.Value,
                NameCls = d.NameLite,
                Category = d.Category == null ? null : d.Category.Value
            });
        }
    }

    public class SanityCheckService : ISanityCheckService
    {
        readonly string _culture;
        readonly IPreferredCultureResolver _cultureResolver;
        readonly IDbContext _dbContext;

        public SanityCheckService(IDbContext dbContext, IPreferredCultureResolver cultureResolver)
        {
            _dbContext = dbContext;
            _cultureResolver = cultureResolver;
            _culture = cultureResolver.Resolve();
        }

        public async Task<IEnumerable<dynamic>> GetCaseValidationRules(SanityCheckCaseViewModel filters, CommonQueryParameters param = null)
        {
            if (filters == null) throw new ArgumentNullException(nameof(filters));
            if (param == null) throw new ArgumentNullException(nameof(param));

            var dataValidations = _dbContext.Set<DataValidation>()
                                            .CaseRules()
                                            .WithRuleOverviewDetails(filters.RuleOverview, _culture)
                                            .WithNameDetails(filters.CaseName)
                                            .WithEventDetails(filters.Event)
                                            .WithStandingInstructionDetails(filters.StandingInstruction)
                                            .WithOtherDetails(filters.Other);

            var caseCharacteristics = GetCaseRelatedDetails(filters.CaseCharacteristics);

            return await (from dv in dataValidations
                          join c in caseCharacteristics on dv.Id equals c.ValidationId
                          select new
                          {
                              dv.Id,
                              RuleDescription = DbFuncs.GetTranslation(dv.RuleDescription, null, dv.RuleDescriptionTid, _culture),
                              InUse = dv.InUseFlag,
                              Deferred = dv.DeferredFlag,
                              Informational = dv.IsWarning,

                              CaseOffice = c.Office != null ? c.Office.Value : null,
                              CaseType = c.CaseType != null ? c.CaseType.Value : null,
                              Jurisdiction = c.Jurisdiction != null ? c.Jurisdiction.Value : null,
                              PropertyType = c.PropertyType != null ? c.PropertyType.Value : null,
                              CaseCategory = c.Category != null ? c.Category.Value : null,
                              SubType = c.SubType != null ? c.SubType.Value : null,
                              Basis = c.Basis != null ? c.Basis.Value : null,

                              ExcludeSubType = dv.NotSubtype,
                              ExcludeCaseType = dv.NotCaseType,
                              ExcludeJurisdiction = dv.NotCountryCode,
                              ExcludePropertyType = dv.NotPropertyType,
                              ExcludeCaseCategory = dv.NotCaseCategory,
                              ExcludeBasis = dv.NotBasis,

                              Pending = (dv.StatusFlag & 1) == 1,
                              Registered = (dv.StatusFlag & 2) == 2,
                              Dead = dv.StatusFlag == 0
                          }).OrderByProperty(param.SortBy, param.SortDir)
                            .ToArrayAsync();
        }

        public async Task<IEnumerable<dynamic>> GetNameValidationRules(SanityCheckNameViewModel filters, CommonQueryParameters param = null)
        {
            if (filters == null) throw new ArgumentNullException(nameof(filters));

            var rows = await GetNameValidationRulesData(filters)
                             .SelectNameSearchData(_cultureResolver.Resolve())
                             .ToArrayAsync();

            return param != null ? rows.OrderByProperty(param.SortBy, param.SortDir) : rows;
        }

        public async Task<CaseSanityCheckRuleModel> GetCaseValidationRule(int id)
        {
            var dataValidations = _dbContext.Set<DataValidation>()
                                            .CaseRules();

            var caseCharacteristics = GetCaseRelatedDetails(new CaseCharacteristicsModel());
            var caseNameDetails = GetCaseNameRelatedDetails();
            var otherDetails = GetOtherDetails(KnownFunctionalArea.Case);

            var data = await (from dv in dataValidations
                              join c in caseCharacteristics on dv.Id equals c.ValidationId
                              join cn in caseNameDetails on dv.Id equals cn.ValidationId
                              join o in otherDetails on dv.Id equals o.ValidationId
                              where dv.Id == id
                              select new CaseSanityCheckRuleModel
                              {
                                  DataValidation = new CaseDataValidationModel
                                  {
                                      Id = dv.Id,
                                      RuleDescription = DbFuncs.GetTranslation(dv.RuleDescription, null, dv.RuleDescriptionTid, _culture),
                                      DisplayMessage = DbFuncs.GetTranslation(dv.DisplayMessage, null, dv.DisplayMessageTid, _culture),
                                      Eventdateflag = dv.Eventdateflag,
                                      Notes = DbFuncs.GetTranslation(dv.Notes, null, dv.NotesTid, _culture),
                                      NotSubtype = dv.NotSubtype,
                                      NotCaseCategory = dv.NotCaseCategory,
                                      NotBasis = dv.NotBasis,
                                      NotCaseType = dv.NotCaseType,
                                      NotCountryCode = dv.NotCountryCode,
                                      NotPropertyType = dv.NotPropertyType,
                                      UsedasFlag = dv.UsedasFlag,
                                      DeferredFlag = dv.DeferredFlag,
                                      InUseFlag = dv.InUseFlag,
                                      IsWarning = dv.IsWarning,
                                      LocalclientFlag = dv.LocalclientFlag,
                                      SupplierFlag = dv.SupplierFlag,
                                      StatusFlag = dv.StatusFlag
                                  },
                                  CaseDetails = c,
                                  CaseNameDetails = cn,
                                  OtherDetails = o
                              }).SingleOrDefaultAsync();

            data?.CaseDetails?.SetStatusIncludeFlags(data.DataValidation?.StatusFlag);
            data?.OtherDetails?.SetEventIncludeFlags(data.DataValidation?.Eventdateflag);

            return data;
        }

        public async Task<NameSanityCheckRuleModel> GetNameValidationRule(int id)
        {
            var nameRulesBasicAndCharacteristics = GetNameValidationRulesData();
            var otherDetails = GetOtherDetails(string.Empty);

            var data = await (from nb in nameRulesBasicAndCharacteristics
                              join o in otherDetails on nb.DataValidation.Id equals o.ValidationId
                              where nb.DataValidation.Id == id
                              select new NameSanityCheckRuleModel
                              {
                                  RuleOverView = new NameOverviewModel
                                  {
                                      RuleDescription = DbFuncs.GetTranslation(nb.DataValidation.RuleDescription, null, nb.DataValidation.RuleDescriptionTid, _culture),
                                      DisplayMessage = DbFuncs.GetTranslation(nb.DataValidation.DisplayMessage, null, nb.DataValidation.DisplayMessageTid, _culture),
                                      Notes = DbFuncs.GetTranslation(nb.DataValidation.Notes, null, nb.DataValidation.NotesTid, _culture),
                                      InformationOnly = nb.DataValidation.IsWarning.HasValue && nb.DataValidation.IsWarning.Value,
                                      Deferred = nb.DataValidation.DeferredFlag,
                                      InUse = nb.DataValidation.InUseFlag,
                                      SanityCheckSql = o.SanityCheckItem,
                                      MayBypassError = o.RoleByPassError
                                  },
                                  Other = new NamesOtherDetailsModel
                                  {
                                      TableColumn = o.TableCode
                                  },
                                  StandingInstruction = new NamesStandingInstructionsModel
                                  {
                                      Characteristic = o.Characteristics,
                                      InstructionType = o.Instruction
                                  },
                                  NameCharacteristics = new NameCharacteristicsModel
                                  {
                                      Category = nb.Category,
                                      ApplyTo = nb.LocalClient.HasValue ? nb.LocalClient.Value ? 1 : 0 : null,
                                      NameLite = nb.NameLite,
                                      NameGroup = nb.NameGroup,
                                      Jurisdiction = nb.Country,
                                      TypeIsClientOnly = nb.IsClientOnly,
                                      TypeIsIndividual = nb.IsIndividual,
                                      TypeIsOrganisation = nb.IsOrganisation,
                                      TypeIsStaff = nb.IsStaff,
                                      TypeIsSupplierOnly = nb.IsSupplierOnly
                                  }
                              }).SingleOrDefaultAsync();

            return data;
        }

        IQueryable<CaseRelatedDataModel> GetCaseRelatedDetails(CaseCharacteristicsModel filters)
        {
            var dataValidations = _dbContext.Set<DataValidation>().AsQueryable();

            var statuses = filters.GetStatusFlags();
            if (statuses != null && statuses.Any())
            {
                dataValidations = dataValidations.Where(r => r.StatusFlag != null && statuses.Any(_ => _ == r.StatusFlag));
            }

            const string countryZ = "ZZZ";

            var validProperty = _dbContext.Set<ValidProperty>();
            var validCategory = _dbContext.Set<ValidCategory>();
            var validBasis = _dbContext.Set<ValidBasis>();
            var validSubtype = _dbContext.Set<ValidSubType>();

            var casePropertyType = _dbContext.Set<PropertyType>();
            var caseType = _dbContext.Set<CaseType>();
            var country = _dbContext.Set<Country>();
            var caseCategory = _dbContext.Set<CaseCategory>();
            var basis = _dbContext.Set<ApplicationBasis>();
            var subType = _dbContext.Set<SubType>();
            var office = _dbContext.Set<Office>();

            return from r in dataValidations
                   join ct1 in caseType on r.CaseType equals ct1.Code into ct1
                   from ct in ct1.DefaultIfEmpty()
                   let vp = validProperty.Where(vp1 => r.PropertyType == vp1.PropertyTypeId && (vp1.CountryId == countryZ || vp1.CountryId == r.CountryCode)).OrderBy(vp2 => vp2.CountryId).FirstOrDefault()
                   join pt1 in casePropertyType on r.PropertyType equals pt1.Code into pt1
                   from pt in pt1.DefaultIfEmpty()
                   join c1 in country on r.CountryCode equals c1.Id into c1
                   from c in c1.DefaultIfEmpty()
                   let vc = validCategory.Where(vc1 => r.PropertyType == vc1.PropertyTypeId && r.CaseType == vc1.CaseTypeId && r.CaseCategory == vc1.CaseCategoryId && (vc1.CountryId == countryZ || vc1.CountryId == r.CountryCode)).OrderBy(vc2 => vc2.CountryId).FirstOrDefault()
                   join cc1 in caseCategory on new { caseType = r.CaseType, caseCategory = r.CaseCategory } equals new { caseType = cc1.CaseTypeId, caseCategory = cc1.CaseCategoryId } into cc1
                   from cc in cc1.DefaultIfEmpty()
                   let vb = validBasis.Where(bs1 => r.PropertyType == bs1.PropertyTypeId && r.Basis == bs1.BasisId && (bs1.CountryId == countryZ || bs1.CountryId == r.CountryCode)).OrderBy(bs2 => bs2.CountryId).FirstOrDefault()
                   join ab1 in basis on r.Basis equals ab1.Code into ab1
                   from ab in ab1.DefaultIfEmpty()
                   let vs = validSubtype.Where(vs1 => r.PropertyType == vs1.PropertyTypeId && r.CaseType == vs1.CaseTypeId && r.CaseCategory == vs1.CaseCategoryId && r.SubType == vs1.SubtypeId && (vs1.CountryId == countryZ || vs1.CountryId == r.CountryCode)).OrderBy(vs2 => vs2.CountryId).FirstOrDefault()
                   join st1 in subType on r.SubType equals st1.Code into st1
                   from st in st1.DefaultIfEmpty()
                   join o1 in office on r.OfficeId equals o1.Id into o1
                   from o in o1.DefaultIfEmpty()
                   where (r.CaseType == filters.CaseType || filters.CaseType == null) &&
                         (r.CaseCategory == filters.CaseCategory || filters.CaseCategory == null) &&
                         (r.PropertyType == filters.PropertyType || filters.PropertyType == null) &&
                         (r.CountryCode == filters.Jurisdiction || filters.Jurisdiction == null) &&
                         (r.SubType == filters.SubType || filters.SubType == null) &&
                         (r.Basis == filters.Basis || filters.Basis == null) &&
                         (r.OfficeId == filters.Office || !filters.Office.HasValue) &&
                         (filters.CaseType == null || r.NotCaseType == filters.CaseTypeExclude || r.NotCaseType == null && filters.CaseTypeExclude == false) &&
                         (filters.CaseCategory == null || r.NotCaseCategory == filters.CaseCategoryExclude || r.NotCaseCategory == null && filters.CaseCategoryExclude == false) &&
                         (filters.PropertyType == null || r.NotPropertyType == filters.PropertyTypeExclude || r.NotPropertyType == null && filters.PropertyTypeExclude == false) &&
                         (filters.Jurisdiction == null || r.NotCountryCode == filters.JurisdictionExclude || r.NotCountryCode == null && filters.JurisdictionExclude == false) &&
                         (filters.Basis == null || r.NotBasis == filters.BasisExclude || r.NotBasis == null && filters.BasisExclude == false) &&
                         (filters.SubType == null || r.NotSubtype == filters.SubTypeExclude || r.NotSubtype == null && filters.SubTypeExclude == false) &&
                         (r.LocalclientFlag == filters.ApplyTo || !filters.ApplyTo.HasValue)
                   select new CaseRelatedDataModel
                   {
                       ValidationId = r.Id,
                       CaseType = ct == null
                           ? null
                           : new PicklistModel<int>
                           {
                               Key = ct.Id,
                               Code = ct.Code,
                               Value = ct == null ? null : DbFuncs.GetTranslation(ct.Name, null, ct.NameTId, _culture)
                           },
                       Office = o == null
                           ? null
                           : new PicklistModel<int>
                           {
                               Key = o.Id,
                               Code = null,
                               Value = DbFuncs.GetTranslation(o.Name, null, o.NameTId, _culture)
                           },
                       Category = vc == null && cc == null
                           ? null
                           : new PicklistModel<string>
                           {
                               Key = vc != null ? vc.CaseCategoryId : cc.CaseCategoryId,
                               Code = vc != null ? vc.CaseCategoryId : cc.CaseCategoryId,
                               Value = vc != null ? DbFuncs.GetTranslation(vc.CaseCategoryDesc, null, vc.CaseCategoryDescTid, _culture) : DbFuncs.GetTranslation(cc.Name, null, cc.NameTId, _culture)
                           },
                       PropertyType = vp == null && pt == null
                           ? null
                           : new PicklistModel<string>
                           {
                               Key = null,
                               Code = vp != null ? vp.PropertyTypeId : pt.Code,
                               Value = vp != null ? DbFuncs.GetTranslation(vp.PropertyName, null, vp.PropertyNameTId, _culture) : DbFuncs.GetTranslation(pt.Name, null, pt.NameTId, _culture)
                           },
                       Jurisdiction = c == null
                           ? null
                           : new PicklistModel<string>
                           {
                               Key = null,
                               Code = c.Id,
                               Value = c.Name
                           },
                       Basis = vb == null && ab == null
                           ? null
                           : new PicklistModel<string>
                           {
                               Key = null,
                               Code = vb != null ? vb.BasisId : ab.Code,
                               Value = vb != null ? DbFuncs.GetTranslation(vb.BasisDescription, null, vb.BasisDescriptionTId, _culture) : DbFuncs.GetTranslation(ab.Name, null, ab.NameTId, _culture)
                           },
                       SubType = vs == null && st == null
                           ? null
                           : new PicklistModel<string>
                           {
                               Key = null,
                               Code = vs != null ? vs.SubtypeId : st.Code,
                               Value = vs != null ? DbFuncs.GetTranslation(vs.SubTypeDescription, null, vs.SubTypeDescriptionTid, _culture) : DbFuncs.GetTranslation(st.Name, null, st.NameTId, _culture)
                           }
                   };
        }

        IQueryable<CaseNameRelatedDataModel> GetCaseNameRelatedDetails()
        {
            var dataValidations = _dbContext.Set<DataValidation>();

            var nameType = _dbContext.Set<NameType>();
            var family = _dbContext.Set<Name.NameFamily>();

            var namesQuery = _dbContext.Set<Name.Name>().Select(_ => new NameLite
            {
                Id = _.Id,
                FirstName = _.FirstName,
                MiddleName = _.MiddleName,
                LastName = _.LastName,
                Title = _.Title,
                Suffix = _.Suffix
            });

            return from r in dataValidations
                   join nt1 in nameType on r.NameType equals nt1.NameTypeCode into nt1
                   from nt in nt1.DefaultIfEmpty()
                   join n1 in namesQuery on r.NameId equals n1.Id into n1
                   from n in n1.DefaultIfEmpty()
                   join nf1 in family on r.FamilyNo equals nf1.Id into nf1
                   from nf in nf1.DefaultIfEmpty()
                   select new CaseNameRelatedDataModel
                   {
                       ValidationId = r.Id,
                       Family = nf == null ? null : new PicklistModel<int> { Key = nf.Id, Code = null, Value = DbFuncs.GetTranslation(nf.FamilyTitle, null, nf.FamilyTitleTid, _culture) },
                       NameLite = n,
                       NameType = nt == null ? null : new PicklistModel<int> { Key = nt.Id, Code = null, Value = DbFuncs.GetTranslation(nt.Name, null, nt.NameTId, _culture) }
                   };
        }

        IQueryable<OtherDataModel> GetOtherDetails(string functionalArea)
        {
            var dataValidations = _dbContext.Set<DataValidation>().AsQueryable();

            var instructionType = _dbContext.Set<InstructionType>();
            var characteristics = _dbContext.Set<Characteristic>();
            var tableCode = _dbContext.Set<TableCode>().Where(_ => _.TableTypeId == (short)ProtectedTableTypes.ValidateColumn && (string.IsNullOrEmpty(functionalArea) || _.UserCode == functionalArea));
            var role = _dbContext.Set<Role>();
            var item = _dbContext.Set<DocItem>();
            var @event = _dbContext.Set<Event.Event>();

            return from r in dataValidations
                   join it1 in instructionType on r.InstructionType equals it1.Code into it1
                   from it in it1.DefaultIfEmpty()
                   join c1 in characteristics on new { flagNo = (short)r.FlagNumber, code = it.Code } equals new { flagNo = c1.Id, code = c1.InstructionTypeCode } into c1
                   from c in c1.DefaultIfEmpty()
                   join tc1 in tableCode on r.ColumnName equals tc1.Id into tc1
                   from tc in tc1.DefaultIfEmpty()
                   join r1 in role on r.CanOverrideRoleId equals r1.Id into r1
                   from ro in r1.DefaultIfEmpty()
                   join i1 in item on r.ItemId equals i1.Id into i1
                   from i in i1.DefaultIfEmpty()
                   join e1 in @event on r.EventNo equals e1.Id into e1
                   from e in e1.DefaultIfEmpty()
                   select new OtherDataModel
                   {
                       ValidationId = r.Id,
                       Instruction = it == null ? null : new PicklistModel<string> { Key = it.Code, Code = it.Code, Value = DbFuncs.GetTranslation(it.Description, null, it.DescriptionTId, _culture) },
                       Characteristics = c == null ? null : new PicklistModel<int> { Key = c.Id, Code = null, Value = DbFuncs.GetTranslation(c.Description, null, c.DescriptionTId, _culture) },
                       TableCode = tc == null ? null : new PicklistModel<int> { Key = tc.Id, Code = null, Value = DbFuncs.GetTranslation(tc.Name, null, tc.NameTId, _culture) },
                       RoleByPassError = ro == null ? null : new PicklistModel<int> { Key = ro.Id, Code = null, Value = DbFuncs.GetTranslation(ro.RoleName, null, ro.RoleNameTId, _culture) },
                       SanityCheckItem = i == null ? null : new PicklistModel<int> { Key = i.Id, Code = i.Name, Value = i.Description },
                       Event = e == null ? null : new PicklistModel<int> { Key = e.Id, Code = e.Code, Value = DbFuncs.GetTranslation(e.Description, null, e.DescriptionTId, _culture) }
                   };
        }

        IQueryable<NameSanityCheckRuleIntermediate> GetNameValidationRulesData(SanityCheckNameViewModel filters = null)
        {
            var namesQuery = _dbContext.Set<Name.Name>().Select(_ => new NameLite
            {
                Id = _.Id,
                FirstName = _.FirstName,
                MiddleName = _.MiddleName,
                LastName = _.LastName,
                Title = _.Title,
                Suffix = _.Suffix
            });

            var dvFiltered = filters != null
                ? _dbContext.Set<DataValidation>()
                            .NameRules()
                            .FilterByNameCharacteristics(filters)
                            .WithRuleOverviewDetails(filters.RuleOverview, _culture)
                            .WithStandingInstructionDetails(filters.StandingInstruction)
                            .WithOtherDetails(filters.Other)
                : _dbContext.Set<DataValidation>();

            var dataValidations = from d in dvFiltered
                                  join c1 in _dbContext.Set<Country>() on d.CountryCode equals c1.Id into c1
                                  from c in c1.DefaultIfEmpty()
                                  join t1 in _dbContext.Set<TableCode>() on d.Category equals t1.Id into t1
                                  from tcc in t1.DefaultIfEmpty()
                                  join n1 in namesQuery on d.NameId equals n1.Id into n1
                                  from n in n1.DefaultIfEmpty()
                                  join nf1 in _dbContext.Set<Name.NameFamily>() on d.FamilyNo equals nf1.Id into nf1
                                  from nf in nf1.DefaultIfEmpty()
                                  select new NameSanityCheckRuleIntermediate
                                  {
                                      DataValidation = d,
                                      NameLite = n,
                                      Category = tcc == null ? null : new PicklistModel<string> { Key = tcc.Id.ToString(), Code = null, Value = DbFuncs.GetTranslation(tcc.Name, null, tcc.NameTId, _culture) },
                                      Country = c == null ? null : new PicklistModel<string> { Key = null, Code = c.Id, Value = c.Name },
                                      LocalClient = d.LocalclientFlag,
                                      NameGroup = nf == null ? null : new PicklistModel<int> { Key = nf.Id, Code = null, Value = DbFuncs.GetTranslation(nf.FamilyTitle, null, nf.FamilyTitleTid, _culture) },
                                      IsOrganisation = d.UsedasFlag.HasValue && d.UsedasFlag.Value % 2 == 0,
                                      IsIndividual = d.UsedasFlag.HasValue && d.UsedasFlag.Value % 2 == 1,
                                      IsStaff = d.UsedasFlag.HasValue && d.UsedasFlag.Value == 3,
                                      IsClientOnly = d.UsedasFlag.HasValue && (d.UsedasFlag.Value == 4 || d.UsedasFlag.Value == 5),
                                      IsSupplierOnly = d.SupplierFlag ?? false
                                  };
            return dataValidations;
        }

        public class NameSanityCheckResult
        {
            public int Id { get; set; }
            public string RuleDescription { get; set; }
            public bool InUse { get; set; }
            public bool Deferred { get; set; }
            public bool? Informational { get; set; }

            public short? UsedAs { get; set; }

            public bool Supplier { get; set; }
            public bool? LocalClient { get; set; }
            public string Jurisdiction { get; set; }
            public string NameGroup { get; set; }

            [JsonIgnore]
            public NameLite NameCls { get; set; }

            public string Name => NameCls?.Formatted();
            public string Category { get; set; }

            public bool Staff => Convert.ToBoolean(UsedAs & NameUsedAs.StaffMember);

            public bool Organization => UsedAs.HasValue && !Individual;

            public bool Individual => Convert.ToBoolean(UsedAs & NameUsedAs.Individual);

            public bool Client => Convert.ToBoolean(UsedAs & NameUsedAs.Client);
        }

        public class NameLite
        {
            public int Id { get; set; }

            public string Title { get; set; }

            public string FirstName { get; set; }
            public string MiddleName { get; set; }
            public string LastName { get; set; }
            public string Suffix { get; set; }

            public string Formatted()
            {
                return new Name.Name(Id)
                {
                    Title = Title,
                    FirstName = FirstName,
                    MiddleName = MiddleName,
                    LastName = LastName,
                    Suffix = Suffix
                }.FormattedWithDefaultStyle();
            }
        }
    }
}