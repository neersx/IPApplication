using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.SchemaMapping.XmlGen;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.SchemaMapping
{
    [Authorize]
    [NoEnrichment]
    public class XmlGenCaseApiController : XmlGenBaseController
    {
        readonly IDbContext _dbContext;

        public XmlGenCaseApiController(IXmlGenService xmlGenService, IDbContext dbContext) : base(xmlGenService)
        {
            _dbContext = dbContext;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("api/cases/generate-xml")]
        public async Task<HttpResponseMessage> Get(int caseId, int mappingId)
        {
            var caseRef = await (from c in _dbContext.Set<Case>()
                                 where c.Id == caseId
                                 select c.Irn).SingleAsync();

            return await GetXmlResponse(mappingId, new Dictionary<string, object>
            {
                {"gstrEntryPoint", caseRef}
            });
        }
    }
}