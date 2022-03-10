using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt.ExistingPriorArtFinders
{
    internal class ExistingIpoIssuedPriorArt : IExistingPriorArtFinder
    {
        readonly IDbContext _dbContext;

        public ExistingIpoIssuedPriorArt(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IQueryable<InprotechKaizen.Model.PriorArt.PriorArt> GetExistingPriorArt(SearchRequest request)
        {
            if (request.IpoSearchType == IpoSearchType.Multiple)
            {
                var resultSet = new List<IQueryable<InprotechKaizen.Model.PriorArt.PriorArt>>();
                var matches = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>().OrderByDescending(pa => pa.LastModified);
                foreach (var ipoSearchRequest in request.MultipleIpoSearch)
                {
                    var number = ipoSearchRequest.OfficialNumber.StripNonAlphanumerics();
                    if (string.IsNullOrWhiteSpace(ipoSearchRequest.Kind))
                    {
                        var q = matches.Where(pa => pa.CountryId == ipoSearchRequest.Country && DbFuncs.StripNonAlphanumerics(pa.OfficialNumber) == number);
                        resultSet.Add(q);
                    }
                    else
                    {
                        var q = matches.Where(pa => pa.CountryId == ipoSearchRequest.Country && DbFuncs.StripNonAlphanumerics(pa.OfficialNumber) == number && pa.Kind == ipoSearchRequest.Kind);
                        resultSet.Add(q);
                    }
                }

                return resultSet.Aggregate((a, b) => a.Union(b));
            }
            else
            {
                var number = request.OfficialNumber.StripNonAlphanumerics();
                var country = request.Country;
                var kind = request.Kind;

                var resultSet = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>()
                                          .OrderByDescending(pa => pa.LastModified)
                                          .Where(pa => DbFuncs.StripNonAlphanumerics(pa.OfficialNumber) == number && pa.Country.Id == country);
                if (!string.IsNullOrWhiteSpace(kind))
                {
                    resultSet = resultSet.Where(pa => pa.Kind == kind);
                }

                return resultSet;
            }
        }
    }
}