using System.Linq;
using System.Web;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Names.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/name")]
    public class NameInternalDetailsController : ApiController
    {
        readonly IDbContext _dbContext;

        public NameInternalDetailsController(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        [HttpGet]
        [RequiresNameAuthorization]
        [RegisterAccess]
        [Route("{nameId:int}/internal-details")]
        public dynamic GetNameInternalDetails(int nameId)
        {
            var name = _dbContext.Set<Name>().Single(v => v.Id == nameId);
            if (name == null)
                throw new HttpException(404, "Unable to find the name.");

            return new 
            {
                name.DateEntered,
                name.DateChanged,
                SoundexCode = name.Soundex
            };
        }
    }
}
