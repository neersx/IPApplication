using System.Linq;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt.ExistingPriorArtFinders
{
    internal class ExistingLiteraturePriorArt : IExistingPriorArtFinder
    {
        readonly IDbContext _dbContext;

        public ExistingLiteraturePriorArt(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IQueryable<InprotechKaizen.Model.PriorArt.PriorArt> GetExistingPriorArt(SearchRequest request)
        {
            var resultSet = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>()
                                      .Where(_ => !_.IsSourceDocument && !(_.IsIpDocument ?? false));

            if (!string.IsNullOrWhiteSpace(request.Description))
            {
                resultSet = resultSet.Where(_ => _.Description != null && _.Description.Contains(request.Description));
            }

            if (!string.IsNullOrWhiteSpace(request.Country))
            {
                resultSet = resultSet.Where(_ => _.CountryId == request.Country);
            }

            if (!string.IsNullOrWhiteSpace(request.Inventor))
            {
                resultSet = resultSet.Where(_ => _.Name != null && _.Name.Contains(request.Inventor));
            }

            if (!string.IsNullOrWhiteSpace(request.Title))
            {
                resultSet = resultSet.Where(_ => _.Title != null && _.Title.Contains(request.Title));
            }

            if (!string.IsNullOrWhiteSpace(request.Publisher))
            {
                resultSet = resultSet.Where(_ => _.Publisher != null && _.Publisher.Contains(request.Publisher));
            }

            return resultSet.OrderBy(pa => pa.Description)
                            .ThenBy(pa => pa.Name)
                            .ThenBy(pa => pa.Title);
        }
    }
}