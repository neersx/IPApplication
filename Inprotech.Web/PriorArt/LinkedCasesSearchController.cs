using System;
using System.Collections.Generic;
using System.IdentityModel.Protocols.WSTrust;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Cases.PriorArt;

namespace Inprotech.Web.PriorArt
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Create)]
    public class LinkedCasesSearchController : ApiController
    {
        readonly ILinkedCaseSearch _linkedCaseSearch;

        public LinkedCasesSearchController(ILinkedCaseSearch linkedCaseSearch)
        {
            _linkedCaseSearch = linkedCaseSearch;
        }

        [HttpGet]
        [Route("api/priorart/linkedCases/search")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyPath = "args.CaseKey")]
        public async Task<PagedResults<LinkedCaseModel>> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "args")]
                                                                SearchRequest args, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                                CommonQueryParameters queryParams = null)
        {
            var query = await _linkedCaseSearch.Search(args, (queryParams ?? CommonQueryParameters.Default).Filters);
            var pagedResult = query.AsOrderedPagedResults(queryParams ?? CommonQueryParameters.Default);
            return pagedResult;
        }

        [HttpGet]
        [Route("api/priorart/linkedCases/search/filterData/{field}")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyPath = "q.CaseKey")]
        public async Task<IEnumerable<dynamic>> GetFilterDataForColumn(string field,
                                                                       [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")]
                                                                       SearchRequest q,
                                                                       [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                                       CommonQueryParameters queryParameters)
        {
            if (field == null) throw new ArgumentNullException(nameof(field));
            if (!LinkedCaseFilters.Contains(field.ToUpper())) throw new InvalidRequestException();

            var results = await _linkedCaseSearch.Search(q, (queryParameters ?? CommonQueryParameters.Default).Filters.Where(f => !f.Field.IgnoreCaseEquals(field)));
            switch (field.ToUpper())
            {
                case "CASEREFERENCE":
                    return results.OrderBy(_ => _.CaseReference).Select(_ => new {Description = _.CaseReference, Code = _.CaseKey.ToString()}).Distinct().ToArray();
                    break;
                case "OFFICIALNUMBER":
                    return results.OrderBy(_ => _.OfficialNumber).Select(_ => new {Description = _.OfficialNumber, Code = _.OfficialNumber}).Distinct().ToArray();
                    break;
                case "JURISDICTION":
                    return results.OrderBy(_ => _.Jurisdiction).Select(_ => new {Description = _.Jurisdiction, Code = _.JurisdictionCode}).Distinct().ToArray();
                    break;
                case "CASESTATUS":
                    return results.OrderBy(_ => _.CaseStatus).Select(_ => new {Description = _.CaseStatus, Code = _.CaseStatusCode != null ? _.CaseStatusCode.ToString() : string.Empty}).Distinct().ToArray();
                    break;
                case "FAMILY":
                    return results.OrderBy(_ => _.Family).Select(_ => new {Description = _.Family, Code = _.FamilyCode}).Distinct().ToArray();
                    break;
                case "PRIORARTSTATUS":
                    return results.OrderBy(_ => _.PriorArtStatus).Select(_ => new {Description = _.PriorArtStatus, Code = _.PriorArtStatusCode.HasValue ? _.PriorArtStatusCode.ToString() : string.Empty}).Distinct().ToArray();
                    break;
                case "DATEUPDATED":
                    return results.OrderBy(_ => _.DateUpdated).Select(_ => new {Description = _.DateUpdated, Code = _.DateUpdated}).Distinct().ToArray();
                    break;
                case "RELATIONSHIP":
                    return new[]
                    {
                        new {Description = "True", Code = true.ToString()},
                        new {Description = "False", Code = false.ToString()}
                    };
                    break;
                case "CASELIST":
                    var caseLists = results.SelectMany(v => v.CaseLists);
                    return caseLists.Select(caseList => new {Description = caseList, Code = caseList}).Distinct().ToArray();
                    break;
                case "LINKEDVIANAMES":
                    return results.OrderBy(_ => _.LinkedViaNames).Select(_ => new {Description = _.LinkedViaNames, Code = _.NameNo + _.NameType}).Distinct().ToArray();
                    break;
            }

            return Enumerable.Empty<dynamic>();
        }
    }

    public class LinkedCaseModel
    {
        public bool IsCaseFirstLinked { get; set; }
        public string CaseReference { get; set; }
        public int CaseKey { get; set; }
        public string OfficialNumber { get; set; }
        public string Jurisdiction { get; set; }
        public string CaseStatus { get; set; }
        public string PriorArtStatus { get; set; }
        public DateTime? DateUpdated { get; set; }
        public bool Relationship { get; set; }
        public string Family { get; set; }
        public string CaseList { get; set; }
        public string LinkedViaNames { get; set; }
        public int Id { get; set; }
        public string FamilyCode { get; set; }
        public string JurisdictionCode { get; set; }
        public short? CaseStatusCode { get; set; }
        public int? PriorArtStatusCode { get; set; }
        public IEnumerable<string> CaseLists { get; set; }
        public int? NameNo { get; set; }
        public string NameType { get; set; }
    }

    public static class LinkedCaseFilters
    {
        public const string CaseReference = "CASEREFERENCE";
        public const string OfficialNumber = "OFFICIALNUMBER";
        public const string Jurisdiction = "JURISDICTION";
        public const string CaseStatus = "CASESTATUS";
        public const string Family = "FAMILY";
        public const string PriorArtStatus = "PRIORARTSTATUS";
        public const string DateUpdated = "DATEUPDATED";
        public const string Relationship = "RELATIONSHIP";
        public const string CaseList = "CASELIST";
        public const string LinkedViaNames = "LINKEDVIANAMES";

        public static bool Contains(string value)
        {
            return value == CaseReference || value == OfficialNumber || value == Jurisdiction || value == CaseStatus || value == Family 
                   || value == PriorArtStatus || value == DateUpdated || value == Relationship || value == CaseList || value == LinkedViaNames;
        }
    }
}