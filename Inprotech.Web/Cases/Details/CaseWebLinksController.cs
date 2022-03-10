using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class CaseWebLinksController : ApiController
    {
        readonly IPreferredCultureResolver _cultureResolver;
        readonly IDbContext _dbContext;
        readonly IDocItemRunner _runner;
        readonly ISecurityContext _securityContext;
        readonly IStaticTranslator _staticTranslator;
        readonly IUriHelper _uriHelper;

        public CaseWebLinksController(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver cultureResolver, IDocItemRunner runner, IStaticTranslator staticTranslator, IUriHelper uriHelper)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _cultureResolver = cultureResolver;
            _runner = runner;
            _staticTranslator = staticTranslator;
            _uriHelper = uriHelper;
        }

        string DocItemUrl(int caseKey, int criteriaNo, int? docItemId)
        {
            return $"apps/api/case/{caseKey}/weblinks/{criteriaNo}/{docItemId}";
        }

        string InvalidLinkUrl(int caseKey, int criteriaNo)
        {
            return $"apps/api/case/{caseKey}/weblinksopen/{criteriaNo}";
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/weblinks")]
        public async Task<IEnumerable<WebLinksData>> GetCaseWebLinks(int caseKey)
        {
            var culture = _cultureResolver.Resolve();
            var isExternalUser = _securityContext.User.IsExternalUser;
            var cd = await (from c in _dbContext.Set<Case>().Where(_ => _.Id == caseKey)
                            join p in _dbContext.Set<CaseProperty>() on c.Id equals p.CaseId into p1
                            from p in p1.DefaultIfEmpty()
                            join rs in _dbContext.Set<Status>() on p.RenewalStatusId equals rs.Id into rs1
                            from rs in rs1.DefaultIfEmpty()
                            join tc in _dbContext.Set<TableCode>() on new
                                {
                                    Id = c.CaseStatus != null && c.CaseStatus.LiveFlag == 0 || rs.LiveFlag == 0 ? (int) KnownStatusCodes.Dead
                                        : c.CaseStatus != null && c.CaseStatus.RegisteredFlag == 1 ? (int) KnownStatusCodes.Registered
                                        : (int) KnownStatusCodes.Pending
                                }
                                equals new {tc.Id} into tc1
                            from tc in tc1.DefaultIfEmpty()
                            select new
                            {
                                OfficeId = c.Office == null ? null : (int?) c.Office.Id,
                                c.TypeId,
                                c.PropertyTypeId,
                                TableCoe = tc.Id,
                                c.CountryId,
                                c.CategoryId,
                                c.SubTypeId,
                                p.Basis
                            })
                .FirstAsync();

            var links = await (from cr in _dbContext.GetCriteriaRows(CriteriaPurposeCodes.CaseLinks, cd.OfficeId, cd.TypeId, cd.PropertyTypeId, cd.CountryId, cd.CategoryId, cd.SubTypeId, cd.Basis, cd.TableCoe)
                               join tc in _dbContext.Set<TableCode>() on cr.GroupId equals tc.Id into tc1
                               from tc in tc1.DefaultIfEmpty()
                               where !isExternalUser || cr.IsPublic
                               select new
                               {
                                   nullAtEnd = cr.GroupId != null,
                                   GroupKey = cr.GroupId,
                                   GroupName = tc == null ? null : DbFuncs.GetTranslation(tc.Name, null, tc.NameTId, culture),
                                   LinkTitle = DbFuncs.GetTranslation(cr.LinkTitle, null, cr.LinkTitle_TId, culture),
                                   LinkDescription = DbFuncs.GetTranslation(cr.LinkDescription, null, cr.LinkDescription_TId, culture),
                                   cr.Url,
                                   cr.BestFit,
                                   cr.DocItemId,
                                   cr.CriteriaNo
                               })
                              .OrderByDescending(_ => _.nullAtEnd)
                              .ThenBy(_ => _.GroupName)
                              .ThenBy(_ => _.GroupKey)
                              .ThenBy(_ => _.BestFit)
                              .ThenBy(_ => _.LinkTitle)
                              .ToArrayAsync();

            return links.GroupBy(_ => new {_.GroupKey, _.GroupName}).Select(_ => new WebLinksData
            {
                GroupName = _.Key.GroupName,
                Links = _.Select(l => new WebLinksData.LinkDetails
                {
                    Url = NormalizeUrl(caseKey, l.CriteriaNo, !string.IsNullOrEmpty(l.Url) ? l.Url : Request.RequestUri.ReplaceStartingFromSegment("apps", DocItemUrl(caseKey, l.CriteriaNo, l.DocItemId)).ToString()),
                    DocItemId = l.DocItemId,
                    CriteriaNo = l.CriteriaNo,
                    LinkTitle = l.LinkTitle,
                    LinkDescription = l.LinkDescription,
                    HasUrl = !string.IsNullOrEmpty(l.Url)
                })
            });
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/weblinks/{criteriaNo:int}/{docItemId:int}")]
        public async Task<HttpResponseMessage> ResolveLink(int caseKey, int criteriaNo, int docItemId)
        {
            var links = await GetCaseWebLinks(caseKey);
            var link = links?.SelectMany(_ => _.Links).FirstOrDefault(_ => _.CriteriaNo == criteriaNo && _.DocItemId == docItemId);
            if (link == null)
            {
                return new HttpResponseMessage(HttpStatusCode.NotFound)
                {
                    ReasonPhrase = "Invalid Request Data"
                };
            }

            var resolvedLink = link.Url;
            if (!link.HasUrl)
            {
                var @case = await _dbContext.Set<Case>().SingleAsync(_ => _.Id == caseKey);
                var dataset = _runner.Run(docItemId, new Dictionary<string, object>
                {
                    {"gstrEntryPoint", @case.Irn},
                    {"gstrUserId", _securityContext.User.Id}
                });
                resolvedLink = dataset.ScalarValueOrDefault<string>();
                if (string.IsNullOrEmpty(resolvedLink))
                {
                    var cultures = _cultureResolver.ResolveAll();
                    return new HttpResponseMessage(HttpStatusCode.OK)
                    {
                        Content = new StringContent(_staticTranslator.Translate("caseWebLinks.invalidDocItemUrl", cultures))
                    };
                }
            }

            return RedirectPage(resolvedLink);
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/weblinksopen/{criteriaNo:int}")]
        public HttpResponseMessage OpenInvalidLink(int caseKey, int criteriaNo)
        {
            var cultures = _cultureResolver.ResolveAll();
            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(_staticTranslator.Translate("caseWebLinks.invalidUrl", cultures))
            };
        }

        HttpResponseMessage RedirectPage(string url)
        {
            var response = Request.CreateResponse(HttpStatusCode.Redirect);
            response.Headers.Location = new Uri(url);
            return response;
        }

        string NormalizeUrl(int caseKey, int criteriaNo, string url)
        {
            if (!_uriHelper.TryAbsolute(url, out var uri))
            {
                return Request.RequestUri.ReplaceStartingFromSegment("apps", InvalidLinkUrl(caseKey, criteriaNo)).ToString();
            }

            return uri.ToString();
        }

        public class WebLinksData
        {
            public string GroupName { get; set; }
            public IEnumerable<LinkDetails> Links { get; set; }

            public class LinkDetails
            {
                public string LinkTitle { get; set; }
                public string LinkDescription { get; set; }
                public string Url { get; set; }

                [JsonIgnore]
                public int CriteriaNo { get; set; }

                [JsonIgnore]
                public int? DocItemId { get; set; }

                [JsonIgnore]
                public bool HasUrl { get; set; }
            }
        }
    }
}