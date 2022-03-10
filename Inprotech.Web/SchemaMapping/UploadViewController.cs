using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.SchemaMappings;

namespace Inprotech.Web.SchemaMapping
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ConfigureSchemaMappingTemplate)]
    [RoutePrefix("api/schemamappings")]
    [NoEnrichment]
    public class UploadViewController : ApiController
    {
        readonly IDbContext _dbContext;

        public UploadViewController(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("uploadview")]
        public async Task<dynamic> Get()
        {
            var mappings = _dbContext
                .Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>()
                .OrderBy(_ => _.Name)
                .Select(_ => new
                {
                    _.Id,
                    _.Name,
                    _.SchemaPackageId,
                    SchemaPackageName = _.SchemaPackage.Name,
                    _.SchemaPackage.IsValid,
                    _.RootNode
                })
                .ToArray();

            var allSchemaPackages = await _dbContext.Set<SchemaPackage>()
                                                    .OrderByDescending(_ => _.Id)
                                                    .ToArrayAsync();

            return new
            {
                Mappings = mappings,
                SchemaPackages = allSchemaPackages
            };
        }
    }
}