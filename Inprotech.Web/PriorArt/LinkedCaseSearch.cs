using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using ServiceStack;

namespace Inprotech.Web.PriorArt
{
    public interface ILinkedCaseSearch
    {
        Task<IEnumerable<LinkedCaseModel>> Search(SearchRequest args, IEnumerable<CommonQueryParameters.FilterValue> filters);
        IQueryable<LinkedSearchModel> Citations(SearchRequest args, IEnumerable<CommonQueryParameters.FilterValue> filters);
    }

    public class LinkedCaseSearch : ILinkedCaseSearch
    {
        readonly IPreferredCultureResolver _culture;
        readonly IDbContext _dbContext;
        readonly IDisplayFormattedName _displayFormattedName;

        public LinkedCaseSearch(IDbContext dbContext, IPreferredCultureResolver culture, IDisplayFormattedName displayFormattedName)
        {
            _dbContext = dbContext;
            _culture = culture;
            _displayFormattedName = displayFormattedName;
        }

        public async Task<IEnumerable<LinkedCaseModel>> Search(SearchRequest args, IEnumerable<CommonQueryParameters.FilterValue> filters)
        {
            var citations = Citations(args, filters);
            var nameIds = citations.Where(_ => _.Name != null).Select(_ => _.Name.Id).Distinct().ToArray();
            var formattedNames = await _displayFormattedName.For(nameIds);
            var result = citations.ToArray().OrderByDescending(_ => _.DateUpdated).GroupBy(_ => _.CaseKey).Select(_ => new LinkedCaseModel
            {
                Id = _.First().Id,
                IsCaseFirstLinked = _.First().IsCaseFirstLinked,
                CaseReference = _.First().CaseRef,
                CaseKey = _.Key,
                OfficialNumber = _.First().OfficialNumber,
                Jurisdiction = _.First().Jurisdiction,
                JurisdictionCode = _.First().JurisdictionCode,
                CaseStatusCode = _.First().CaseStatusCode,
                CaseStatus = _.First().CaseStatus,
                PriorArtStatus = _.First().PriorArtStatus,
                PriorArtStatusCode = _.First().PriorArtStatusCode,
                DateUpdated = _.First().DateUpdated,
                Relationship = _.First().Relationship,
                Family = _.Select(f => f.Family).Where(c => !string.IsNullOrEmpty(c)).Distinct().FirstOrDefault(),
                FamilyCode = _.Select(f => f.FamilyCode).Where(c => !string.IsNullOrEmpty(c)).Distinct().FirstOrDefault(),
                CaseList = string.Join(", ", _.Select(s => s.CaseList).Where(c => c.Length > 0).Distinct().OrderBy(cl => cl)),
                CaseLists = _.Select(s => s.CaseList),
                NameNo = _.Any(n => n.Name != null) ? _.First(n => n.Name != null).Name.Id : (int?) null,
                NameType = _.Any(n => n.NameType != null) ? _.First(n => n.NameType != null).NameType.NameTypeCode : null,
                LinkedViaNames = _.Any(n => n.Name != null && n.NameType != null)
                    ? FormatLinkedName(formattedNames?.Get(_.First(n => n.Name != null).Name.Id).Name,
                                       _.First(n => n.Name != null).Name.NameCode,
                                       _.First(n => n.NameType != null).NameType)
                    : _.Any(n => n.Name != null) ? FormatLinkedName(formattedNames?.Get(_.First(n => n.Name != null).Name.Id).Name,
                                                                    _.First(n => n.Name != null).Name.NameCode, null) : null
            }).ToArray();

            return result;
        }

        public IQueryable<LinkedSearchModel> Citations(SearchRequest args, IEnumerable<CommonQueryParameters.FilterValue> filters)
        {
            var preferredCulture = _culture.Resolve();
            var tableCodes = _dbContext.Set<TableCode>();
            var caseSearchResults = _dbContext.Set<CaseSearchResult>();
            var familySearchResults = _dbContext.Set<FamilySearchResult>();
            var caseListSearchResults = _dbContext.Set<CaseListSearchResult>();
            var nameSearchResults = _dbContext.Set<NameSearchResult>();
            var citations = from cse in caseSearchResults
                            join tc in tableCodes
                                on cse.StatusId equals tc.Id into tc1
                            from tc in tc1.DefaultIfEmpty()
                            join fsr in familySearchResults
                                on cse.FamilyPriorArtId equals fsr.Id into fsr1
                            from fsr in fsr1.DefaultIfEmpty()
                            join cls in caseListSearchResults
                                on cse.CaseListPriorArtId equals cls.Id into cls1
                            from cls in cls1.DefaultIfEmpty()
                            join nsr in nameSearchResults
                                on cse.NamePriorArtId equals nsr.Id into nsr1
                            from nsr in nsr1.DefaultIfEmpty()
                            where cse.PriorArtId == args.SourceDocumentId
                            select new LinkedSearchModel
                            {
                                CaseSearchResult = cse,
                                Id = cse.Id,
                                PriorArtId = cse.PriorArtId,
                                IsCaseFirstLinked = cse.CaseFirstLinkedTo ?? false,
                                CaseRef = cse.Case.Irn,
                                CaseKey = cse.CaseId,
                                OfficialNumber = cse.Case.CurrentOfficialNumber,
                                Jurisdiction = cse.Case.Country.Name,
                                JurisdictionCode = cse.Case.CountryId,
                                CaseStatus = cse.Case.CaseStatus.Name,
                                CaseStatusCode = cse.Case.StatusCode,
                                PriorArtStatus = tc != null ? tc.Name : string.Empty,
                                PriorArtStatusCode = cse.StatusId,
                                DateUpdated = DbFuncs.TruncateTime(cse.UpdateDate),
                                ModifiedDateTime = cse.UpdateDate,
                                Relationship = cse.IsCaseRelationship ?? false,
                                Family = fsr != null ? DbFuncs.GetTranslation(fsr.Family.Name, null, fsr.Family.NameTId, preferredCulture) : string.Empty,
                                FamilyCode = fsr != null ? fsr.FamilyId : string.Empty,
                                CaseList = cls != null ? DbFuncs.GetTranslation(cls.CaseList.Name, null, cls.CaseList.NameTId, preferredCulture) : string.Empty,
                                Name = nsr != null ? nsr.Name : null,
                                NameType = nsr != null ? nsr.NameType : null
                            };

            foreach (var filter in filters)
            {
                switch (filter.Field)
                {
                    case "caseReference":
                        var (_, caseKeys) = SplitToList<int>(filter.Value);
                        citations = citations.Where(_ => caseKeys.Contains(_.CaseKey));
                        break;
                    case "officialNumber":
                        var (hasEmptyOfficialNumbers, officialNumbers) = SplitToList<string>(filter.Value); 
                        citations = citations.Where(_ => hasEmptyOfficialNumbers && _.OfficialNumber == null || officialNumbers.Contains(_.OfficialNumber));
                        break;
                    case "jurisdiction":
                        var (_, jurisdictions) = SplitToList<string>(filter.Value);
                        citations = citations.Where(_ => jurisdictions.Contains(_.JurisdictionCode));
                        break;
                    case "caseStatus":
                        var (hasEmptyStatuses, caseStatuses) = SplitToList<short?>(filter.Value);
                        citations = citations.Where(_ => hasEmptyStatuses && _.CaseStatusCode == null || caseStatuses.Contains(_.CaseStatusCode));
                        break;
                    case "family":
                        var (hasEmptyFamily, familyCodes) = SplitToList<string>(filter.Value);
                        citations = citations.Where(_ => hasEmptyFamily && _.FamilyCode == string.Empty || familyCodes.Contains(_.FamilyCode));
                        break;
                    case "priorArtStatus":
                        var (hasEmptyPriorArtStatus, priorArtStatus) = SplitToList<int?>(filter.Value);
                        citations = citations.Where(_ => hasEmptyPriorArtStatus && _.PriorArtStatusCode == null || priorArtStatus.Contains(_.PriorArtStatusCode));
                        break;
                    case "dateUpdated":
                        var (hasEmptyDate, dates) = SplitToList<DateTime>(filter.Value);
                        var dateOnly = dates.Select(v => DbFuncs.TruncateTime(v));
                        citations = citations.Where(_ => hasEmptyDate && _.DateUpdated == null || dateOnly.Contains(DbFuncs.TruncateTime(_.DateUpdated).Value));
                        break;
                    case "relationship":
                        var (_, relationshipFlags) = SplitToList<bool>(filter.Value);
                        citations = citations.Where(_ => relationshipFlags.Contains(_.Relationship));
                        break;
                    case "caseList":
                        var (hasEmptyCaseList, caseLists) = SplitToList<string>(filter.Value);
                        citations = citations.Where(_ => hasEmptyCaseList && _.CaseList == string.Empty || caseLists.Contains(_.CaseList));
                        break;
                    case "linkedViaNames":
                        var (hasEmptyName, linkedViaNames) = SplitToList<string>(filter.Value);
                        citations = citations.Where(_ => hasEmptyName && _.Name == null || linkedViaNames.Contains(_.Name.Id + _.NameType.NameTypeCode));
                        break;
                }
            }

            return citations;

            (bool containsEmpty, List<T> list) SplitToList<T>(string filterValue)
            {
                var stringIds = filterValue.Split(',');
                var hasEmpty = stringIds.Contains("empty");
                var stringIdsWithoutEmpty = stringIds.Where(v => v != "empty");
                return (hasEmpty, stringIdsWithoutEmpty.Where(_ => !string.IsNullOrWhiteSpace(_)).ToList().ConvertTo<List<T>>());
            }
        }

        public string FormatLinkedName(string formattedName, string nameCode, NameType nameType)
        {
            var returnFormattedName = formattedName;

            if (nameType == null) return returnFormattedName;
            if (nameType.ShowNameCode.HasValue)
            {
                returnFormattedName = ((ShowNameCode) nameType.ShowNameCode).Format(formattedName, nameCode);
            }

            returnFormattedName = returnFormattedName + $" {{{nameType.NameTypeCode}}}";
            return returnFormattedName;
        }
    }

    public class LinkedSearchModel
    {
        public CaseSearchResult CaseSearchResult { get; set; }
        public int Id { get; set; }
        public int PriorArtId { get; set; }
        public bool IsCaseFirstLinked { get; set; }
        public string CaseRef { get; set; }
        public int CaseKey { get; set; }
        public string OfficialNumber { get; set; }
        public string Jurisdiction { get; set; }
        public string JurisdictionCode { get; set; }
        public string CaseStatus { get; set; }
        public short? CaseStatusCode { get; set; }
        public string PriorArtStatus { get; set; }
        public int? PriorArtStatusCode { get; set; }
        public DateTime? DateUpdated { get; set; }
        public bool Relationship { get; set; }
        public string Family { get; set; }
        public string FamilyCode { get; set; }
        public string CaseList { get; set; }
        public Name Name { get; set; }
        public NameType NameType { get; set; }
        public DateTime ModifiedDateTime { get; set; }
    }
}