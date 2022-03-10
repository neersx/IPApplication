using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.Innography.Ids
{
    public class IpOneDataDocumentFinder : IAsyncPriorArtEvidenceFinder
    {
        readonly IDbContext _dbContext;
        readonly IDocumentApiClient _documentApiClient;
        readonly string _ipOneOrigin = "IP One Data";
        readonly IPatentScoutUrlFormatter _patentScoutUrlFormatter;
        readonly ILogger<IpOneDataDocumentFinder> _logger;

        public IpOneDataDocumentFinder(IDocumentApiClient documentApiClient, IPatentScoutUrlFormatter patentScoutUrlFormatter, IDbContext dbContext, ILogger<IpOneDataDocumentFinder> logger)
        {
            _documentApiClient = documentApiClient;
            _patentScoutUrlFormatter = patentScoutUrlFormatter;
            _dbContext = dbContext;
            _logger = logger;
        }

        public async Task<SearchResult> Find(SearchRequest request, SearchResultOptions options)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            if (request.SourceType != PriorArtTypes.Ipo)
            {
                return new SearchResult
                {
                    Source = GetType().Name,
                    Matches = new PagedResults<Match>(Enumerable.Empty<Match>(), 0)
                };
            }

            var matches = new List<Match>();

            if (request.IpoSearchType == IpoSearchType.Multiple)
            {
                var countryCodes = request.MultipleIpoSearch.Select(v => v.Country);
                var countries = _dbContext.Set<Country>().Where(v => countryCodes.Contains(v.Id)).ToDictionary(v => v.Id, v => v.Name);
                var taskList = new List<Task>();
                foreach (var ipoSearchRequest in request.MultipleIpoSearch)
                {
                    try
                    {
                        taskList.Add(Matches(ipoSearchRequest.Country, ipoSearchRequest.OfficialNumber, ipoSearchRequest.Kind, countries[ipoSearchRequest.Country]));
                    }
                    catch (Exception e)
                    {
                        if (e.IsFatal())
                            throw;

                        _logger.Exception(e);
                    }
                }

                await Task.WhenAll(taskList);
            }
            else
            {
                var countryName = _dbContext.Set<Country>().SingleOrDefault(_ => _.Id == request.Country)?.Name;
                await Matches(request.Country, request.OfficialNumber, request.Kind, countryName);
            }

            async Task Matches(string countryCode, string officialNumber, string kind, string countryName)
            {
                var r = await _documentApiClient.Documents(countryCode, officialNumber, kind);
                var e = r.Result?.DocumentDetails
                         .Select(d => d.CountryCode == "US"
                                     ? CreateMatchForTheStates(d, options, countryName)
                                     : CreateMatchForRestOfTheWorld(d, options, countryName))
                         .ToArray() ?? Array.Empty<Match>();
                matches.AddRange(e);
            }

            return new SearchResult
            {
                Source = GetType().Name,
                Matches = new PagedResults<Match>(matches, matches.Count)
            };

        }

        Match CreateMatchForTheStates(DocumentDetails d, SearchResultOptions options, string countryName)
        {
            var singleSignOn = options.ReferenceHandling.IsIpPlatformSession;

            return new Match
            {
                Id = d.IpId,
                Title = d.Title,
                Kind = d.KindCode,
                Abstract = d.Abstract,
                Reference = $"{d.CountryCode}-{d.Number}-{d.KindCode}",
                ApplicationDate = d.ApplicationDate.FormatAsUtcDateValue(),
                PublishedDate = d.DocumentType.IgnoreCaseContains("publication")
                    ? d.Date.FormatAsUtcDateValue()
                    : null,
                GrantedDate = d.DocumentType.IgnoreCaseContains("grant")
                    ? d.Date.FormatAsUtcDateValue()
                    : null,
                Name = string.Join("; ", ((d.Inventor?.Length == 0 ? Array.Empty<string>() : d.Inventor) ?? Array.Empty<string>()).Select(i => i.TrimEnd())),
                ReferenceLink = _patentScoutUrlFormatter.CreatePatentScoutReferenceLink(d.IpId, singleSignOn),
                IsComplete = true,
                CountryName = countryName,
                CountryCode = d.CountryCode,
                Origin = _ipOneOrigin,
                OfficialNumber = d.Number
            };
        }

        Match CreateMatchForRestOfTheWorld(DocumentDetails d, SearchResultOptions options, string countryName)
        {
            var singleSignOn = options.ReferenceHandling.IsIpPlatformSession;

            return new Match
            {
                Id = d.IpId,
                Title = d.Title,
                Kind = d.KindCode,
                Abstract = d.Abstract,
                Reference = $"{d.CountryCode}-{d.Number}-{d.KindCode}",
                ApplicationDate = d.ApplicationDate.FormatAsUtcDateValue(),
                PublishedDate = d.Date.FormatAsUtcDateValue(),
                GrantedDate = null,
                Name = string.Join("; ", ((d.Applicant?.Length == 0 ? Array.Empty<string>() : d.Applicant) ?? Array.Empty<string>()).Select(i => i.TrimEnd())),
                ReferenceLink = _patentScoutUrlFormatter.CreatePatentScoutReferenceLink(d.IpId, singleSignOn),
                IsComplete = true,
                CountryName = countryName,
                CountryCode = d.CountryCode,
                Origin = _ipOneOrigin,
                OfficialNumber = d.Number
            };
        }
    }
}