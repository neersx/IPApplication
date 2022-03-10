using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.SchemaMapping
{
    [Authorize]
    [RoutePrefix("api/schemamappings")]
    [NoEnrichment]
    public class XmlViewController : ApiController
    {
        readonly IDbContext _dbContext;

        public XmlViewController(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }
        
        [HttpGet]
        [Route("xmlView/{id}")]
        public dynamic Get(int id)
        {
            var mapping = _dbContext.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().SingleOrDefault(_ => _.Id == id);

            if (mapping == null)
            {
                HttpResponseExceptionHelper.RaiseNotFound("Mapping not found: id=" + id);
                return null;
            }

            return new
            {
                mapping.Name
            };
        }
    }
}