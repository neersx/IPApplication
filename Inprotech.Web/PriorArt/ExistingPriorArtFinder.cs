using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Innography;
using Inprotech.Web.PriorArt.ExistingPriorArtFinders;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt
{
    public class ExistingPriorArtFinder : IAsyncPriorArtEvidenceFinder
    {
        readonly IDbContext _dbContext;
        readonly IIndex<int, IExistingPriorArtFinder> _existingPriorArtFinder;
        readonly IExistingPriorArtMatchBuilder _matchBuilder;

        public ExistingPriorArtFinder(IDbContext dbContext, IExistingPriorArtMatchBuilder matchBuilder, IIndex<int, IExistingPriorArtFinder> existingPriorArtFinder)
        {
            _dbContext = dbContext;
            _matchBuilder = matchBuilder;
            _existingPriorArtFinder = existingPriorArtFinder;
        }

        public async Task<SearchResult> Find(SearchRequest request, SearchResultOptions options)
        {
            var sourceDocumentId = request.SourceDocumentId;
            var caseKey = request.CaseKey;
            var resultSet = _existingPriorArtFinder[request.SourceType].GetExistingPriorArt(request);

            if (caseKey != null)
            {
                var caseId = (int) caseKey;
                var caseSearchResults = _dbContext.Set<CaseSearchResult>().Where(_ => _.CaseId == caseId && _.CaseFirstLinkedTo == true);

                var caseQuery = from pa in resultSet
                                join t in caseSearchResults on pa.Id equals t.PriorArtId into casePriorArtResult
                                from t in casePriorArtResult.DefaultIfEmpty()
                                select new
                                {
                                    Art = pa,
                                    SearchResult = t,
                                    IsSourceDocument = pa.SourceDocuments.Any(sd => sd.Id == sourceDocumentId),
                                    IsCitedPriorArt = pa.CitedPriorArt.Any(sd => sd.Id == sourceDocumentId)
                                };
                if (request.SourceType == PriorArtTypes.Source)
                {
                    caseQuery = from rs in caseQuery
                                orderby rs.Art.SourceType != null ? rs.Art.SourceType.Name : string.Empty, rs.Art.IssuingCountry != null ? rs.Art.IssuingCountry.Name : string.Empty, rs.Art.Description
                                select rs;
                }
                else
                {
                    caseQuery = from rs in caseQuery
                                orderby rs.Art.LastModified descending
                                select rs;
                }

                var res = (await caseQuery.Distinct().ToArrayAsync())
                                   .Select(_ => _matchBuilder.Build(_.Art, sourceDocumentId,
                                                                    _.IsSourceDocument || _.SearchResult != null && sourceDocumentId == null || _.IsCitedPriorArt,
                                                                    options,
                                                                    _.SearchResult,
                                                                    caseId))
                                   .ToList()
                                   .AsOrderedPagedResults(request.QueryParameters ?? CommonQueryParameters.Default.Extend(new CommonQueryParameters {SortBy = "LastModifiedDate", SortDir = "desc"}));

                return new SearchResult
                {
                    Source = GetType().Name,
                    Matches = res
                };
            }

            var query = resultSet.Select(rs => new
            {
                Art = rs,
                IsSourceDocument = rs.SourceDocuments.Any(sd => sd.Id == sourceDocumentId),
                IsCitedPriorArt = rs.CitedPriorArt.Any(_ => _.Id == sourceDocumentId)
            });

            var pagedResult = query.Distinct()
                                   .ToArray()
                                   .Select(_ => _matchBuilder.Build(_.Art,
                                                                    sourceDocumentId,
                                                                    _.IsSourceDocument || _.IsCitedPriorArt,
                                                                    options))
                                   .ToList()
                                   .AsOrderedPagedResults(request.QueryParameters ?? CommonQueryParameters.Default.Extend(new CommonQueryParameters {SortBy = "LastModifiedDate", SortDir = "desc"}));

            return new SearchResult
            {
                Source = GetType().Name,
                Matches = pagedResult
            };
        }
    }

    public interface IExistingPriorArtMatchBuilder
    {
        Match Build(InprotechKaizen.Model.PriorArt.PriorArt priorArt, int? sourceDocumentId, bool isCited, SearchResultOptions options, CaseSearchResult searchResult = null, int? caseKey = null);
        IEnumerable<KeyValuePair<string, string>> GetPriorArtTranslations();
    }

    public class ExistingPriorArtMatchBuilder : IExistingPriorArtMatchBuilder
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IPatentScoutUrlFormatter _referenceFormatter;

        public ExistingPriorArtMatchBuilder(IPatentScoutUrlFormatter referenceFormatter, IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _referenceFormatter = referenceFormatter;
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public IEnumerable<KeyValuePair<string, string>> GetPriorArtTranslations()
        {
            var culture = _preferredCultureResolver.Resolve();
            var priorArtTranslations = _dbContext.Set<TableCode>()
                                                 .Select(_ => new
                                                 {
                                                     _.Id,
                                                     Description = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                                                     _.TableTypeId
                                                 })
                                                 .Where(_ => _.TableTypeId == (short) TableTypes.PriorArtTranslation)
                                                 .ToArray();

            return priorArtTranslations.Select(_ => new KeyValuePair<string, string>(_.Id.ToString(), _.Description));
        }

        public Match Build(InprotechKaizen.Model.PriorArt.PriorArt priorArt, int? sourceDocumentId, bool isCited, SearchResultOptions options, CaseSearchResult searchResult = null, int? caseKey = null)
        {
            if (priorArt == null) throw new ArgumentNullException(nameof(priorArt));

            return new ExistingPriorArtMatch
            {
                Id = priorArt.Id.ToString(),
                Reference = priorArt.OfficialNumber,
                Title = priorArt.Title,
                Classes = priorArt.Classes,
                City = priorArt.City,
                SubClasses = priorArt.SubClasses,
                ReportReceived = priorArt.ReportReceived?.Date,
                ReportIssued = priorArt.ReportIssued?.Date,
                Publication = priorArt.Publication,
                IssuingJurisdiction = priorArt.IssuingCountry?.Name,
                SourceType = priorArt.SourceType?.Name,
                Citation = priorArt.Citation,
                Kind = priorArt.Kind,
                Abstract = priorArt.Abstract,
                SourceDocumentId = sourceDocumentId,
                IsCited = isCited,
                ReferenceLink = _referenceFormatter.CreatePatentScoutReferenceLink(priorArt.CorrelationId, options.ReferenceHandling.IsIpPlatformSession),
                CountryName = priorArt.Country?.Name,
                CountryCode = priorArt.Country?.Id,
                Country = new SourceJurisdiction {Key = priorArt.Country?.Id, Value = priorArt.Country?.Name},
                Origin = "Inprotech",
                PriorArtStatus = caseKey != null && searchResult != null ? GetPriorArtStatus(searchResult) : string.Empty,
                ApplicationDate = priorArt.ApplicationFiledDate?.Date,
                GrantedDate = priorArt.GrantedDate?.Date,
                PublishedDate = priorArt.PublishedDate?.Date,
                Name = priorArt.Name,
                Translation = priorArt.Translation,
                Description = priorArt.Description,
                Comments = priorArt.Comments,
                PriorityDate = priorArt.PriorityDate?.Date,
                PtoCitedDate = priorArt.PtoCitedDate?.Date,
                RefDocumentParts = priorArt.RefDocumentParts,
                LastModifiedDate = priorArt.LastModified,
                Publisher = priorArt.Publisher,
                Published = priorArt.PublishedDate?.Date
            };
        }

        string GetPriorArtStatus(CaseSearchResult caseSearchResult)
        {
            return caseSearchResult.StatusId != null ? _dbContext.Set<TableCode>().Single(_ => _.Id == caseSearchResult.StatusId).Name : string.Empty;
        }
    }
}