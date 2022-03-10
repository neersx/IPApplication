using System;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.BulkCaseImport.NameResolution;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.BulkCaseImport
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.BulkCaseImport)]
    [RoutePrefix("api/bulkcaseimport/unresolvedname")]
    public class UnresolvedNameController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IMapCandidates _mapCandidates;
        readonly INameMapper _nameMapper;

        public UnresolvedNameController(IDbContext dbContext, IMapCandidates mapCandidates, INameMapper nameMapper)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (mapCandidates == null) throw new ArgumentNullException("mapCandidates");
            if (nameMapper == null) throw new ArgumentNullException("nameMapper");
            _dbContext = dbContext;
            _mapCandidates = mapCandidates;
            _nameMapper = nameMapper;
        }

        [HttpGet]
        [Route("candidates")]
        public dynamic Get(int id, int? candidateId = null)
        {
            var unresolvedName = _dbContext.Set<EdeUnresolvedName>().Single(n => n.Id == id);

            return new
                   {
                       MapCandidates = _mapCandidates.For(unresolvedName, candidateId)
                   };
        }

        [HttpPost]
        [Route("mapname")]
        public dynamic MapName(MapNameRequest request)
        {
            _nameMapper.Map(request.BatchId, request.UnresolvedNameId, request.MapNameId);
            return new { Result = "success" };
        }

        public class MapNameRequest
        {
            public int BatchId;
            public int UnresolvedNameId;
            public int MapNameId;
        }
    }
}