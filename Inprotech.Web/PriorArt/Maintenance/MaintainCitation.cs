using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt.Maintenance
{
    public interface IMaintainCitation
    {
        Task<bool> DeleteCitation(int searchPriorArtId, int citedPriorArtId);
    }

    public class MaintainCitation : IMaintainCitation
    {
        readonly IDbContext _dbContext;

        public MaintainCitation(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<bool> DeleteCitation(int searchPriorArtId, int citedPriorArtId)
        {
            var priorArt = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>()
                                     .SingleOrDefault(v => v.Id == searchPriorArtId)
                                     ?.CitedPriorArt
                                     .SingleOrDefault(q => q.Id == citedPriorArtId);
            if (priorArt== null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>()
                      .SingleOrDefault(v => v.Id == searchPriorArtId)
                      ?.CitedPriorArt.Remove(priorArt);

            await _dbContext.SaveChangesAsync();

            return true;
        }
    }
}
