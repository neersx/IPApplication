using System.Data.Entity;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Names.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/name")]
    public class NameHeaderController : ApiController
    {
        readonly IDbContext _dbContext;
        
        public NameHeaderController(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        [HttpGet]
        [RequiresNameAuthorization]
        [Route("{nameKey:int}/header")]
        public async Task<dynamic> GetNameHeader(int nameKey)
        {
            var name = await _dbContext.Set<Name>().SingleAsync(v => v.Id == nameKey);
            return new
            {
                Title = name.Formatted()
            };
        }
    }
}

