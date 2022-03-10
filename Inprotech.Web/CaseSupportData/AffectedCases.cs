using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.Search;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.CaseSupportData
{
    public interface IAffectedCases
    {
        Task<IEnumerable<SearchResult.Column>> GetAffectedCasesColumns(int caseId);

        Task<SearchResult> GetAffectedCases(int caseId, CommonQueryParameters qp, AffectedCasesFilterModel filter = null);
        dynamic GetCaseRefAndNameType(int caseId);
        Task<IEnumerable<AffectedCasesData>> GetAffectedCasesData(int caseId, CommonQueryParameters qp, AffectedCasesFilterModel filter);
    }

    public class AffectedCases : IAffectedCases
    {
        readonly IDbContext _dbContext;
        readonly IDisplayFormattedName _formattedName;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IStaticTranslator _staticTranslator;
        readonly ICommonQueryService _commonQueryService;

        public AffectedCases(IDbContext dbContext, IDisplayFormattedName formattedName, IStaticTranslator staticTranslator, IPreferredCultureResolver preferredCultureResolver,
                             ICommonQueryService commonQueryService)
        {
            _dbContext = dbContext;
            _formattedName = formattedName;
            _staticTranslator = staticTranslator;
            _preferredCultureResolver = preferredCultureResolver;
            _commonQueryService = commonQueryService ?? throw new ArgumentNullException("commonQueryService");
        }

        public async Task<IEnumerable<SearchResult.Column>> GetAffectedCasesColumns(int caseId)
        {
            var interimResults = await _dbContext.Set<RecordalStep>().Where(_ => _.CaseId == caseId)
                                                 .Select(_ => new
                                                 {
                                                     StepNo = _.StepId,
                                                     TypeNo = _.TypeId,
                                                     TypeName = _.RecordalType.RecordalTypeName
                                                 }).OrderBy(_ => _.StepNo).ToArrayAsync();

            var cultures = _preferredCultureResolver.ResolveAll().ToArray();
            var columnsList = new List<SearchResult.Column>();
            var statusTranslatedValue = _staticTranslator.TranslateWithDefault("caseview.affectedCases.columns.status", cultures);
            foreach (var step in interimResults)
            {
                var sc = new SearchResult.Column
                {
                    Id = "step" + step.StepNo,
                    FieldId = "step" + step.StepNo,
                    Title = $"{step.TypeName} ({step.StepNo})",
                    Format = "Boolean"
                };

                var sc1 = new SearchResult.Column
                {
                    Id = "status" + step.StepNo,
                    FieldId = "status" + step.StepNo,
                    Title = $"{statusTranslatedValue} ({step.StepNo})",
                    Format = "String"
                };
                columnsList.Add(sc);
                columnsList.Add(sc1);
            }

            columnsList.AddRange(GetColumnsList().OrderBy(_ => _.Order).Select(col => new SearchResult.Column
            {
                Id = col.Id,
                FieldId = col.Id,
                Title = col.Title,
                Format = "String",
                IsColumnFreezed = col.IsFreeze,
                IsHyperlink = col.LinkArgs != null,
                LinkArgs = col.LinkArgs,
                LinkType = col.LinkType
            }));

            return columnsList;
        }

        public async Task<SearchResult> GetAffectedCases(int caseId, CommonQueryParameters qp, AffectedCasesFilterModel filter = null)
        {
            var results = await GetAffectedCasesData(caseId, qp, filter);
            var formattedResults = (await GetFormattedNames(results)).ToArray();
            var sortedResults = SortAndPageResults(qp, formattedResults);
            var dynamicResult = GetDynamicResult(sortedResults);
            var colFormats = await GetAffectedCasesColumns(caseId);
            var rows = dynamicResult.Select(x => ReformatSearchResultRow(x, colFormats)).ToArray();

            var searchResults = new SearchResult
            {
                TotalRows = formattedResults.Length,
                Columns = colFormats,
                Rows = rows
            };

            return searchResults;
        }

        public async Task<IEnumerable<AffectedCasesData>> GetAffectedCasesData(int caseId, CommonQueryParameters qp, AffectedCasesFilterModel filter)
        {
            var affectedCases = _dbContext.Set<RecordalAffectedCase>().Where(_ => _.CaseId == caseId);
            var interimResults = await (from ac in affectedCases
                                        join rs in _dbContext.Set<RecordalStep>().Where(_ => _.CaseId == caseId) on new { a = ac.CaseId, b = ac.RecordalTypeNo } equals new { a = rs.CaseId, b = rs.TypeId }
                                        join ag in _dbContext.Set<CaseName>().Where(_ => _.NameTypeId == KnownNameTypes.Agent) on ac.RelatedCaseId equals ag.CaseId into ag1
                                        from ag in ag1.DefaultIfEmpty()
                                        join o in _dbContext.Set<CaseName>().Where(_ => _.NameTypeId == KnownNameTypes.Owner) on ac.RelatedCaseId equals o.CaseId into o1
                                        from o in o1.DefaultIfEmpty()
                                        where (ac.RecordalStepSeq.HasValue && rs.Id == ac.RecordalStepSeq) || !ac.RecordalStepSeq.HasValue
                                        select new
                                        {
                                            ac.SequenceNo,
                                            CaseId = ac.RelatedCaseId,
                                            CaseReference = ac.RelatedCase != null ? ac.RelatedCase.Irn : null,
                                            CountryCode = ac.RelatedCase != null ? ac.RelatedCase.CountryId : ac.CountryId,
                                            Country = ac.RelatedCase != null ? ac.RelatedCase.Country.Name : ac.Country.Name,
                                            OfficialNo = ac.RelatedCase != null ? ac.RelatedCase.CurrentOfficialNumber : ac.OfficialNumber,
                                            AgentId = ac.Agent != null ? ac.Agent.Id : ag != null ? ag.NameId : (int?)null,
                                            IsInheritedAgent = ac.Agent == null && ag != null,
                                            ac.RecordalTypeNo,
                                            rs.StepId,
                                            RecordalType = ac.RecordalType.RecordalTypeName,
                                            OwnerId = o != null ? o.NameId : (int?)null,
                                            ac.Status,
                                            ac.RequestDate,
                                            ac.RecordDate,
                                            ac.RecordalStepSeq,
                                            TypeName = ac.RecordalType.RecordalTypeName,
                                            PropertyType = ac.RelatedCase != null ? ac.RelatedCase.PropertyType.Name : null,
                                            CaseStatus = ac.RelatedCase != null ? ac.RelatedCase.CaseStatus : null
                                        }).OrderBy(_ => _.SequenceNo).ToArrayAsync();

            var statusValues = GetTranslatedValuesForStatus();

            var results = interimResults.GroupBy(_ => new { _.CaseId, _.CountryCode, _.OfficialNo })
                                        .Select(_ => new AffectedCasesData
                                        {
                                            RowKey = caseId + "^" + _.Key.CaseId + "^" + _.Key.CountryCode + "^" + _.Key.OfficialNo,
                                            CaseId = _.Key.CaseId,
                                            CaseReference = _.First().CaseReference,
                                            CountryCode = _.Key.CountryCode,
                                            Country = _.First().Country,
                                            OfficialNo = _.Key.OfficialNo ?? string.Empty,
                                            Steps = _.GroupBy(s => new { s.TypeName, s.RecordalStepSeq }).OrderBy(s => s.First().StepId).Select(s => new AffectedCasesStep
                                            {
                                                Name = s.Key.TypeName,
                                                Id = s.FirstOrDefault()?.RecordalTypeNo,
                                                Status = s.FirstOrDefault()?.Status,
                                                StepNo = s.FirstOrDefault()?.StepId
                                            }),
                                            OwnerIds = _.Where(o => o.OwnerId != null).Select(o => (int)o.OwnerId).Distinct().ToArray(),
                                            AgentId = _.First().AgentId,
                                            IsInheritedAgent = _.First().IsInheritedAgent,
                                            PropertyType = _.First().PropertyType,
                                            CaseStatus = GetCaseStatus(_.First().CaseStatus, statusValues)
                                        });
            results = _commonQueryService.Filter(results, qp);

            if (filter != null)
            {
                results = ApplyFilters(results, filter).ToArray();
            }

            return results;
        }

        public dynamic GetCaseRefAndNameType(int caseKey)
        {
            var culture = _preferredCultureResolver.Resolve();
            var nameType = _dbContext.Set<NameType>().First(x => x.NameTypeCode == KnownNameTypes.Agent);
            var name = DbFuncs.GetTranslation(nameType.Name, null, nameType.NameTId, culture);
            var irn = _dbContext.Set<Case>().Single(x => x.Id == caseKey).Irn;
            return new { caseRef = irn, nameType = name };
        }
        IEnumerable<AffectedCasesData> ApplyFilters(IEnumerable<AffectedCasesData> response, AffectedCasesFilterModel filter)
        {

            if (filter.RecordalStatus != null && filter.RecordalStatus.Length > 0)
            {
                response = response.Where(x => x.Steps
                                                        .Any(y => filter.RecordalStatus
                                                                        .Any(z => z == y.Status)));
            }
            if (filter.OwnerId != null)
                response = response.Where(x => x.OwnerIds.Any(y => y == (int)filter.OwnerId));
            if (filter.StepNo != null)
                response = response.Where(x => x.Steps.Any(y => y.StepNo == (int)filter.StepNo));
            if (filter.RecordalTypeNo != null)
                response = response.Where(x => x.Steps.Any(y => y.Id == (int)filter.RecordalTypeNo));
            if (filter.CaseReference != null)
                response = response.Where(x => !string.IsNullOrWhiteSpace(x.CaseReference) && x.CaseReference.ToLower().Contains(filter.CaseReference.ToLower()));
            if (filter.Jurisdictions != null && filter.Jurisdictions.Length > 0)
                response = response.Where(x => filter.Jurisdictions.Any(y => y == x.CountryCode));
            if (filter.CaseStatus != null && filter.CaseStatus.Length > 0)
                response = response.Where(x => filter.CaseStatus.Any(y => y == x.CaseStatus));

            return response;
        }

        IEnumerable<AffectedCaseColumn> GetColumnsList()
        {
            var cultures = _preferredCultureResolver.ResolveAll().ToArray();
            var translateLabel = "caseview.affectedCases.columns.";
            var list = new List<AffectedCaseColumn>
            {
                new AffectedCaseColumn("caseReference", _staticTranslator.TranslateWithDefault(translateLabel + "caseRef", cultures), 0, true)
                {
                    LinkArgs = new[] {"caseId", "caseReference"},
                    LinkType = "CaseDetails"
                },
                new AffectedCaseColumn("country", _staticTranslator.TranslateWithDefault(translateLabel + "jurisdiction", cultures), 1, true),
                new AffectedCaseColumn("officialNo", _staticTranslator.TranslateWithDefault(translateLabel + "officialNo", cultures), 2, true)
                {
                    LinkArgs = new[] {"caseId", "officialNo"},
                    LinkType = "CaseDetails"
                },
                new AffectedCaseColumn("owner", _staticTranslator.TranslateWithDefault(translateLabel + "currentOwner", cultures), 3),
                new AffectedCaseColumn("agent", _staticTranslator.TranslateWithDefault(translateLabel + "foreignAgent", cultures), 4)
                {
                    LinkArgs = new[] {"agentId", "agent"},
                    LinkType = "NameDetails"
                },
                new AffectedCaseColumn("propertyType", _staticTranslator.TranslateWithDefault(translateLabel + "propertyType", cultures), 5),
                new AffectedCaseColumn("caseStatus", _staticTranslator.TranslateWithDefault(translateLabel + "caseStatus", cultures), 6)
            };
            return list;
        }

        IDictionary<string, string> GetTranslatedValuesForStatus()
        {
            var cultures = _preferredCultureResolver.ResolveAll().ToArray();
            return new Dictionary<string, string>
            {
                {KnownKotCaseStatus.Registered, _staticTranslator.TranslateWithDefault("status.registered", cultures)},
                {KnownKotCaseStatus.Pending, _staticTranslator.TranslateWithDefault("status.pending", cultures)},
                {KnownKotCaseStatus.Dead, _staticTranslator.TranslateWithDefault("status.dead", cultures)}
            };
        }

        string GetCaseStatus(Status caseStatus, IDictionary<string, string> statusValues)
        {
            var isRegistered = caseStatus?.IsRegistered ?? false;
            var isPending = caseStatus == null || caseStatus.IsLive && !caseStatus.IsRegistered;
            var isDead = caseStatus != null && !caseStatus.IsLive;

            if (isRegistered) return statusValues[KnownKotCaseStatus.Registered];
            if (isPending) return statusValues[KnownKotCaseStatus.Pending];
            return isDead ? statusValues[KnownKotCaseStatus.Dead] : string.Empty;
        }

        async Task<IEnumerable<AffectedCasesData>> GetFormattedNames(IEnumerable<AffectedCasesData> results)
        {
            var casesData = results as AffectedCasesData[] ?? results.ToArray();
            if (!casesData.Any()) return casesData;

            var showNameCodeArray = await (from n in _dbContext.Set<NameType>()
                                    where n.NameTypeCode == KnownNameTypes.Agent || n.NameTypeCode == KnownNameTypes.Owner
                                    select new
                                    {
                                        n.NameTypeCode,
                                        ShowNameCode = n.ShowNameCode ?? 0
                                    }).ToArrayAsync();

            var namesList = new List<int>();
            namesList.AddRange(casesData.Where(_ => _.AgentId.HasValue).Select(_ => (int)_.AgentId));
            namesList.AddRange(casesData.Where(_ => _.OwnerIds.Any()).SelectMany(_ => _.OwnerIds));
            var formattedNames = await _formattedName.For(namesList.Distinct().ToArray());
            foreach (var r in casesData)
            {
                if (r.AgentId.HasValue)
                {
                    var agentShowNameCode = showNameCodeArray.First(_ => _.NameTypeCode == KnownNameTypes.Agent);
                    var nameControl = formattedNames[(int) r.AgentId];
                    r.Agent = ((ShowNameCode) agentShowNameCode.ShowNameCode).Format(nameControl.Name, nameControl.NameCode);
                }

                if (r.OwnerIds.Any())
                {
                    var ownerShowNameCode = showNameCodeArray.First(_ => _.NameTypeCode == KnownNameTypes.Owner);
                    r.Owner = string.Join("; ", r.OwnerIds.Select(_ => ((ShowNameCode) ownerShowNameCode.ShowNameCode).Format(formattedNames?.Get(_).Name, formattedNames?.Get(_).NameCode)));
                }
            }

            return casesData;
        }

        IEnumerable<Dictionary<string, object>> GetDynamicResult(IEnumerable<AffectedCasesData> results)
        {
            if (results == null) throw new ArgumentNullException(nameof(results));

            var dynamicResult = new List<Dictionary<string, object>>();
            foreach (var r in results)
            {
                dynamic dyn = new Dictionary<string, object>();
                foreach (var member in r.GetType().GetProperties())
                {
                    if (member.Name != "Steps")
                    {
                        dyn[member.Name.ToCamelCase()] = member.GetValue(r, null);
                    }
                }

                foreach (var step in r.Steps)
                {
                    dyn[$"step{step.StepNo}"] = true;
                    dyn[$"status{step.StepNo}"] = step.Status;
                }

                dynamicResult.Add(dyn);
            }

            return dynamicResult;
        }

        static Dictionary<string, object> ReformatSearchResultRow(Dictionary<string, dynamic> row, IEnumerable<SearchResult.Column> columnFormats)
        {
            var returnValue = new Dictionary<string, object>();

            var columns = columnFormats.ToList();
            foreach (var col in columns)
            {
                if (!row.TryGetValue(col.Id, out var cell)) continue;

                if (!col.IsHyperlink)
                {
                    returnValue[col.Id] = cell;
                    continue;
                }

                returnValue[col.Id] = new
                {
                    value = cell,
                    link = col.LinkArgs
                              .ToDictionary(k => k, row.Get)
                };
            }

            // non-presentation columns
            foreach (var cell in row.Where(cell => columns.All(x => x.Id != cell.Key))) returnValue[cell.Key] = cell.Value;

            return returnValue;
        }

        static IEnumerable<AffectedCasesData> SortAndPageResults(CommonQueryParameters qp, IEnumerable<AffectedCasesData> rows)
        {
            if (!string.IsNullOrEmpty(qp.SortBy))
            {
                var sortedValue = qp.SortBy.Split('.');
                rows = rows.OrderByProperty(sortedValue[0], qp.SortDir);
            }
            else
            {
                rows = rows.OrderByProperty("caseReference", qp.SortDir);
            }
            return rows?.Skip(qp.Skip ?? 0).Take(qp.Take ?? int.MaxValue);
        }
    }

    public class AffectedCaseColumn
    {
        public AffectedCaseColumn(string id, string title, short order, bool isFreeze = false)
        {
            Id = id;
            Title = title;
            Order = order;
            IsFreeze = isFreeze;
        }

        public string Id { get; set; }
        public string Title { get; set; }
        public short Order { get; set; }
        public bool IsFreeze { get; set; }

        public IEnumerable<string> LinkArgs { get; set; }
        public string LinkType { get; set; }
    }

    public class AffectedCasesData
    {
        public int? CaseId { get; set; }
        public string CaseReference { get; set; }
        public string CountryCode { get; set; }
        public string Country { get; set; }
        public string OfficialNo { get; set; }
        public IEnumerable<AffectedCasesStep> Steps { get; set; }
        public IEnumerable<int> OwnerIds { get; set; }
        public string Owner { get; set; }
        public int? AgentId { get; set; }
        public string Agent { get; set; }
        public string PropertyType { get; set; }
        public string CaseStatus { get; set; }
        public string RowKey { get; set; }
        public bool IsInheritedAgent { get; set; }
    }
    
    public class AffectedCasesStep
    {
        public int? Id { get; set; }
        public string Name { get; set; }
        public string Status { get; set; }
        public int? StepNo { get; set; }
    }
}