using System.Linq;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt.ExistingPriorArtFinders
{
    internal class ExistingSourcePriorArt : IExistingPriorArtFinder
    {
        readonly IDbContext _dbContext;

        public ExistingSourcePriorArt(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IQueryable<InprotechKaizen.Model.PriorArt.PriorArt> GetExistingPriorArt(SearchRequest request)
        {
            var resultSet = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>()
                                      .Where(_ => _.IsSourceDocument);
            if (!string.IsNullOrWhiteSpace(request.Country))
            {
                resultSet = resultSet.Where(_ => _.IssuingCountryId == request.Country);
            }

            if (!string.IsNullOrWhiteSpace(request.Description))
            {
                resultSet = resultSet.Where(_ => _.Description != null && _.Description.Contains(request.Description));
            }

            if (!string.IsNullOrWhiteSpace(request.Publication))
            {
                resultSet = resultSet.Where(_ => _.Publication != null && _.Publication.Contains(request.Publication));
            }

            if (!string.IsNullOrWhiteSpace(request.Comments))
            {
                resultSet = resultSet.Where(_ => _.Comments != null && _.Comments.Contains(request.Comments));
            }

            if (request.SourceId.HasValue)
            {
                resultSet = resultSet.Where(_ => _.SourceTypeId == request.SourceId);
            }

            return resultSet
                   .OrderBy(pa => pa.SourceType != null ? pa.SourceType.Name : string.Empty)
                   .ThenBy(pa => pa.IssuingCountry != null ? pa.IssuingCountry.Name : string.Empty)
                   .ThenBy(pa => pa.Description);
        }
    }
}