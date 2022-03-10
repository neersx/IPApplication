using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Accounting.Time;
using Inprotech.Web.Search.Name;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting.Creditor;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Names.Extensions;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/names")]
    public class NamesPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IListName _listName;
        readonly INameAccessSecurity _nameAccessSecurity;
        readonly CommonQueryParameters _queryParameters;
        readonly ISecurityContext _securityContext;
        readonly Func<DateTime> _now;
        readonly IInprotechVersionChecker _versionChecker;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IViewAccessAllowedStaffResolver _timeViewAccessResolver;

        public NamesPicklistController(IListName listName, IDbContext dbContext,
                                       INameAccessSecurity nameAccessSecurity, ISecurityContext securityContext,
                                       Func<DateTime> now, IInprotechVersionChecker versionChecker,
                                       IPreferredCultureResolver preferredCultureResolver,
                                       IViewAccessAllowedStaffResolver timeViewAccessResolver)
        {
            _listName = listName;
            _dbContext = dbContext;
            _nameAccessSecurity = nameAccessSecurity;
            _securityContext = securityContext;
            _queryParameters = CommonQueryParameters.Default.Extend(new CommonQueryParameters {SortBy = "DisplayName"});
            _now = now;
            _versionChecker = versionChecker;
            _preferredCultureResolver = preferredCultureResolver;
            _timeViewAccessResolver = timeViewAccessResolver;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(Name))]
        public PagedResults Names(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
            CommonQueryParameters queryParameters
                = null, string search = "", string filterNameType = "",
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "entityTypes")]
            EntityTypes entityTypes = null, bool? showCeased = false, int? associatedNameId = null)
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));
            var now = _now();

            Name FromResult(NameListItem n)
            {
                var name = new Name
                {
                    Key = n.Id,
                    Code = n.NameCode,
                    DisplayName = n.DisplayName,
                    Remarks = n.Remarks,
                    PositionToShowCode = n.ShowNameCode,
                    CountryCode = n.CountryCode,
                    CountryName = n.CountryName,
                    DisplayMainEmail = n.DisplayMainEmail
                };

                if (showCeased != true) return name;

                name.Ceased = n.DateCeased;
                name.IsGrayedRow = n.DateCeased != null && n.DateCeased.Value.Date <= now.Date;
                return name;
            }

            var buildDisplayNameCode = _versionChecker.CheckMinimumVersion(14);
            var result = _listName.Get(out var rowCount, search, filterNameType, entityTypes, showCeased,
                                       MapColumn(extendedQueryParams.SortBy),
                                       extendedQueryParams.SortDir,
                                       extendedQueryParams.Skip,
                                       extendedQueryParams.Take, associatedNameId, buildDisplayNameCode)
                                  .Select(FromResult);

            return new PagedResults(result, rowCount);
        }

        [HttpGet]
        [Route("timesheetViewAccess")]
        [PicklistPayload(typeof(Name))]
        public async Task<PagedResults> NamesWithTimesheetViewAccess(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
            CommonQueryParameters queryParameters = null, string search = "")
        {
            var allowedStaffIds = await _timeViewAccessResolver.Resolve();

            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            Name FromResult(NameListItem n)
            {
                var name = new Name
                {
                    Key = n.Id,
                    Code = n.NameCode,
                    DisplayName = n.DisplayName,
                    Remarks = n.Remarks,
                    PositionToShowCode = n.ShowNameCode
                };

                return name;
            }

            var buildDisplayNameCode = _versionChecker.CheckMinimumVersion(14);
            var result = _listName.GetSpecificNames(out var rowCount,
                                                    search,
                                                    new EntityTypes {IsStaff = true}, allowedStaffIds.ToList(),
                                                    MapColumn(extendedQueryParams.SortBy),
                                                    extendedQueryParams.SortDir,
                                                    extendedQueryParams.Skip,
                                                    extendedQueryParams.Take,
                                                    buildDisplayNameCode)
                                  .Select(FromResult);

            return new PagedResults(result, rowCount);
        }

        [HttpGet]
        [Route("aliastype/{alias}")]
        [PicklistPayload(typeof(Name))]
        public PagedResults EdeDataSourceNames(string alias,
                                               [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                               CommonQueryParameters queryParameters
                                                   = null, string search = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var edeNames = from n in _dbContext.Set<InprotechKaizen.Model.Names.Name>()
                           join na in _dbContext.Set<NameAlias>() on n.Id equals na.Name.Id
                           where na.AliasType.Code.Equals(alias)
                           select n;

            var accessibleNames = edeNames.ToArray().Where(n => _nameAccessSecurity.CanView(n));

            var enumerable = accessibleNames as InprotechKaizen.Model.Names.Name[] ?? accessibleNames.ToArray();

            var result = enumerable.Select(n => new Name
            {
                Key = n.Id,
                Code = n.NameCode,
                DisplayName = n.Formatted(),
                Remarks = n.Remarks
            });

            if (!string.IsNullOrEmpty(search))
            {
                result = result.Where(_ => _.Code.Equals(search, StringComparison.InvariantCultureIgnoreCase) ||
                                           _.DisplayName.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);
            }

            var names = result as Name[] ?? result.ToArray();
            var executedResults = names.OrderByProperty(extendedQueryParams.SortBy, extendedQueryParams.SortDir)
                                       .Skip(extendedQueryParams.Skip.GetValueOrDefault())
                                       .Take(extendedQueryParams.Take.GetValueOrDefault());

            return new PagedResults(executedResults, names.Count());
        }

        [HttpGet]
        [RequiresNameAuthorization]
        [Route("{NameId}")]
        public NameDetails GetNameDetails(int nameId)
        {
            var isExternalUser = _securityContext.User.IsExternalUser;
            var results = from v in _dbContext.Set<InprotechKaizen.Model.Names.Name>()
                          join s in _dbContext.Set<Employee>() on v.Id equals s.Id into e
                          from ss in e.DefaultIfEmpty()
                          join cr in _dbContext.Set<Creditor>() on v.Id equals cr.NameId into crr
                          from cr in crr.DefaultIfEmpty()
                          where v.Id == nameId
                          select new
                          {
                              Name = v,
                              Staff = ss
                          };
            var data = results.FirstOrDefault();
            if (data == null)
                return new NameDetails();

            var organization = data.Name.IsIndividual && !data.Name.IsStaff && !data.Name.IsOrganisation ? _dbContext.Set<AssociatedName>().FirstOrDefault(v => v.RelatedNameId == data.Name.Id && v.Relationship == KnownRelations.Employs)?.Name : null;

            var culture = _preferredCultureResolver.Resolve();
            string filesInCountries = null;
            var filesIn = _dbContext.Set<FilesIn>().Where(_ => _.NameId == nameId).Select(_ => DbFuncs.GetTranslation(_.Jurisdiction.Name, null, _.Jurisdiction.NameTId, culture)).ToArray();
            if (filesIn.Any())
            {
                filesInCountries = string.Join(", ", filesIn.OrderBy(_ => _));
            }

            var returnName = new NameDetails
            {
                Key = data.Name.Id,
                Code = data.Name.NameCode,
                IsStaff = data.Name.IsStaff,
                IsOrganisation = data.Name.IsOrganisation,
                IsIndividual = data.Name.IsIndividual,
                DisplayName = data.Name.Formatted(),
                OrganisationName = organization?.Formatted(),
                OrganisationCode = organization?.NameCode,
                PostalAddress = data.Name.PostalAddress()?.Formatted(),
                StreetAddress = isExternalUser && data.Name.IsStaff ? null : data.Name.StreetAddress()?.Formatted(),
                MainPhone = data.Name.MainPhone()?.Formatted(),
                MainEmail = data.Name.MainEmailAddress(),
                DateCeased = isExternalUser && data.Name.IsStaff ? null : data.Name.DateCeased,
                Group = isExternalUser && data.Name.IsStaff ? null : data.Name.NameFamily?.FamilyTitle,
                StartDate = isExternalUser && data.Name.IsStaff ? null : data.Staff?.StartDate,
                StaffClassification = isExternalUser && data.Name.IsStaff ? null : (data.Name.IsStaff && data.Staff?.StaffClassification != null ? _dbContext.Set<TableCode>().FirstOrDefault(v => v.Id == data.Staff.StaffClassification)?.Name : null),
                CapacityToSign = isExternalUser && data.Name.IsStaff ? null : (data.Name.IsStaff && data.Staff?.CapacityToSign != null ? _dbContext.Set<TableCode>().FirstOrDefault(v => v.Id == data.Staff.CapacityToSign)?.Name : null),
                ProfitCenter = isExternalUser && data.Name.IsStaff ? null : data.Name.IsStaff ? data.Staff?.ProfitCentre : null,
                DebtorRestrictionFlag = data.Name.ClientDetail?.DebtorStatus?.RestrictionAction != null,
                IsExternalView = isExternalUser,
                SearchKey1 = data.Name.SearchKey1,
                SearchKey2 = data.Name.SearchKey2,
                Nationality = data.Name.Nationality?.Id,
                Remarks = data.Name.Remarks,
                TaxNo = data.Name.TaxNumber,
                Fax = data.Name.MainFax().FormattedOrNull(),
                CompanyNo = data.Name.Organisation?.RegistrationNo,
                Incorporated = data.Name.Organisation?.Incorporated,
                ParentEntity = data.Name.Organisation?.Parent?.Formatted(),
                Category = data.Name.ClientDetail?.Category?.Name,
                SignOffName = data.Staff?.SignOffName,
                AbbreviatedName = data.Staff?.AbbreviatedName,
                IsSupplier = data.Name?.SupplierFlag == 1,
                FormalSalutation = data.Name.Individual?.FormalSalutation,
                InformalSalutation = data.Name.Individual?.CasualSalutation,
                Lead = GetLeadDetails(nameId),
                FilesIn = filesInCountries
            };

            return returnName;
        }

        [RequiresNameAuthorization]
        public LeadViewDetails GetLeadDetails(int nameId)
        {
            var userId = _securityContext.User.Id;
            var hasTaskSecurity = _dbContext.GetTopicSecurity(userId, "501", false, DateTime.Now).Any(x => x.IsAvailable);
            if (!hasTaskSecurity)
                return null;

            var tableCodes = _dbContext.Set<TableCode>();
            var associatedNames = _dbContext.Set<AssociatedName>().Where(x => x.Relationship == KnownNameRelations.ResponsibilityOf);
            var culture = _preferredCultureResolver.Resolve();
            var lead = (from l in _dbContext.Set<LeadDetails>()
                        join an in associatedNames on l.Name.Id equals an.Name.Id into an1
                        from an in an1.DefaultIfEmpty()
                        join tc in tableCodes on l.LeadSource equals tc.Id into ls1
                        from tc in ls1.DefaultIfEmpty()
                        join lsh in _dbContext.Set<LeadStatusHistory>() on l.Id equals lsh.Id into lsh1
                        from lsh in lsh1.DefaultIfEmpty().OrderByDescending(x => x.LOGDATETIMESTAMP)
                        join tc1 in tableCodes on lsh.LeadStatus equals tc1.Id into ls2
                        from tc1 in ls2.DefaultIfEmpty()
                        where l.Id == nameId && (an == null || an.Sequence == associatedNames.Where(x => x.Id == l.Id).Select(_ => _.Sequence).Min())
                        select new
                        {
                            Lead = l,
                            LeaseSourceName = DbFuncs.GetTranslation(tc.Name, null, tc.NameTId, culture),
                            LeadStatusName = DbFuncs.GetTranslation(tc1.Name, null, tc1.NameTId, culture),
                            AssociatedName = an.RelatedName
                        }).FirstOrDefault();

            if (lead == null) return null;

            return new LeadViewDetails()
            {
                LeadOwner = lead.AssociatedName?.Formatted(),
                LeadStatus = lead.LeadStatusName,
                LeadSource = lead.LeaseSourceName,
                EstRevenue = lead.Lead.EstimatedRevLocal,
                Comments = lead.Lead.Comments
            };
        }

        static string MapColumn(string column)
        {
            switch (column?.ToLower())
            {
                case "key":
                    return "Id";
                case "code":
                    return "NameCode";
                default:
                    return column;
            }
        }
    }

    public class Name
    {
        public int Key { get; set; }
        public string Code { get; set; }
        public string DisplayName { get; set; }
        public string Remarks { get; set; }
        public DateTime? Ceased { get; set; }
        public bool IsGrayedRow { get; set; }
        public bool? IsUnavailable { get; set; }
        public decimal? PositionToShowCode { get; set; }
        public string CountryCode { get; set; }
        public string CountryName { get; set; }
        public string DisplayMainEmail { get; set; }
    }

    public class NameDetails
    {
        public int Key { get; set; }
        public string Code { get; set; }
        public bool IsStaff { get; set; }
        public bool IsOrganisation { get; set; }
        public bool IsIndividual { get; set; }
        public bool IsSupplier { get; set; }
        public string DisplayName { get; set; }
        public string OrganisationName { get; set; }
        public string OrganisationCode { get; set; }
        public string PostalAddress { get; set; }
        public string StreetAddress { get; set; }
        public string MainPhone { get; set; }
        public string MainEmail { get; set; }
        public string MainContact { get; set; }
        public DateTime? DateCeased { get; set; }
        public string Group { get; set; }
        public DateTime? StartDate { get; set; }
        public string StaffClassification { get; set; }
        public string CapacityToSign { get; set; }
        public string ProfitCenter { get; set; }
        public bool DebtorRestrictionFlag { get; set; }
        public bool IsExternalView { get; set; }
        public string SearchKey1 { get; set; }
        public string SearchKey2 { get; set; }
        public string Nationality { get; set; }
        public string Category { get; set; }
        public string Remarks { get; set; }
        public string Fax { get; set; }
        public string TaxNo { get; set; }
        public string CompanyNo { get; set; }
        public string Incorporated { get; set; }
        public string ParentEntity { get; set; }
        public string SignOffName { get; set; }
        public string AbbreviatedName { get; set; }
        public string SupplierType { get; set; }
        public string InformalSalutation { get; set; }
        public string FormalSalutation { get; set; }
        public LeadViewDetails Lead { get; set; }

        public string FilesIn { get; set; }
    }

    public class LeadViewDetails
    {
        public string LeadOwner { get; set; }
        public string LeadStatus { get; set; }
        public string LeadSource { get; set; }
        public decimal? EstRevenue { get; set; }
        public string Comments { get; set; }
    }
}