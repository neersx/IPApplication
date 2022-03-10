using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class CaseViewImagesController : ApiController
    {
        readonly IDbContext _dbContext;

        public CaseViewImagesController(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }
        
        [HttpGet]
        [RequiresCaseAuthorization]
        [RegisterAccess]
        [Route("{caseKey:int}/images")]
        public dynamic GetCaseImages(int caseKey)
        {
            var results = from v in _dbContext.Set<CaseImage>()
                          join q in _dbContext.Set<TableCode>() on v.ImageType equals q.Id into l
                          from q in l.DefaultIfEmpty()
                          orderby v.ImageSequence
                          where v.CaseId == caseKey && q.Id != KnownImageTypes.Attachment
                          select new
                          {
                              CaseKey = v.CaseId,
                              ImageKey = v.ImageId,
                              ImageDescription = v.CaseImageDescription,
                              ImageType = q.Name,
                              v.FirmElementId
                          };

            return results;
        }
    }
}
