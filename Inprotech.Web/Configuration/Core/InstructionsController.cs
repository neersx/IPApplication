using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Web.Configuration.Core
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.MaintainBaseInstructions)]
    public class InstructionsController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public InstructionsController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [Route("api/instructions")]
        [NoEnrichment]
        public dynamic Instructions(int typeId)
        {
            if (!_dbContext.Set<InstructionType>().Any(_ => _.Id == typeId))
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }
            var culture = _preferredCultureResolver.Resolve();
            return (from i in _dbContext.Set<Instruction>()
                    join it in _dbContext.Set<InstructionType>() on i.InstructionTypeCode equals it.Code into i1
                    from it in i1
                    where it.Id == typeId
                    select new
                           {
                               i.Id,
                               TypeId = it.Id,
                               Description = DbFuncs.GetTranslation(i.Description, null, i.DescriptionTId, culture)
                           }).ToArray();
        }
    }
}