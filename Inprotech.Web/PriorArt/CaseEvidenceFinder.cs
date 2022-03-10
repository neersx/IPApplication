using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt
{
    public class CaseEvidenceFinder : IAsyncPriorArtEvidenceFinder
    {
        readonly IDbContext _dbContext;

        public CaseEvidenceFinder(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<SearchResult> Find(SearchRequest request, SearchResultOptions options)
        {
            if (request.SourceType != PriorArtTypes.Ipo)
            {
                return new SearchResult
                {
                    Source = GetType().Name,
                    Matches = new PagedResults<Match>(Enumerable.Empty<Match>(), 0)
                };
            }
            if (request.IpoSearchType == IpoSearchType.Multiple)
            {
                return await FindMultiples(request.MultipleIpoSearch);
            }
            var matches = await MatchingCase(request.OfficialNumber, request.Country);
            return new SearchResult
            {
                Source = GetType().Name,
                Matches = new PagedResults<Match>(matches, matches.Length)
            };
        }

        async Task<SearchResult> FindMultiples(IpoSearchRequest[] requestMultipleIpoSearch)
        {
            var resultSet = new List<Match>();

            foreach (var ipoSearchRequest in requestMultipleIpoSearch)
            {
                var matches = await MatchingCase(ipoSearchRequest.OfficialNumber, ipoSearchRequest.Country);
                resultSet.AddRange(matches);
            }

            return new SearchResult
            {
                Source = GetType().Name,
                Matches = new PagedResults<Match>(resultSet.ToArray(), resultSet.Count)
            };
        }

        async Task<Match[]> MatchingCase(string officialNumber, string countryCode)
        {
            if (string.IsNullOrWhiteSpace(officialNumber))
            {
                throw new ArgumentException("A valid official number is required.");
            }
            if (string.IsNullOrWhiteSpace(countryCode))
            {
                throw new ArgumentException("A valid country is required.");
            }
            var number = officialNumber.StripNonAlphanumerics();
            var caseIndexes = _dbContext.Set<CaseIndexes>().Where(_ => _.Source == CaseIndexSource.OfficialNumbers && _.GenericIndex == number);
            var cases = _dbContext.Set<Case>().Where(_ => _.Country.Id == countryCode && caseIndexes.Any(i => i.CaseId == _.Id));
            var result = await (from c in cases
                                select new
                                {
                                    c.Id,
                                    c.Irn,
                                    c.Title,
                                    CurrentOfficialNumber = caseIndexes.FirstOrDefault(_ => _.GenericIndex == number) == null ? c.CurrentOfficialNumber : caseIndexes.FirstOrDefault(_ => _.GenericIndex == number).GenericIndex,
                                    CountryName = c.Country.Name,
                                    CountryCode = c.Country.Id,
                                    CaseStatus = c.CaseStatus.Name
                                }).ToArrayAsync();
            var matches = result.Select(
                                        c => new Match
                                        {
                                            Id = c.Id.ToString(),
                                            Reference = c.Irn,
                                            Title = c.Title,
                                            OfficialNumber = c.CurrentOfficialNumber,
                                            CountryName = c.CountryName,
                                            CountryCode = c.CountryCode,
                                            CaseStatus = c.CaseStatus,
                                            Origin = "Inprotech Case"
                                        }).ToArray();
            return matches;
        }
    }
}