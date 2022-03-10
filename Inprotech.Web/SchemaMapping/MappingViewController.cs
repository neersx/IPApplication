using System.Collections.Generic;
using System.Data.Entity;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.SchemaMapping.Data;
using Inprotech.Integration.SchemaMapping.Xsd;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.SchemaMapping
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ConfigureSchemaMappingTemplate)]
    [RoutePrefix("api/schemamappings")]
    [NoEnrichment]
    public class MappingViewController : ApiController
    {
        readonly IDocItemReader _docItemReader;
        readonly IDbContext _dbContext;
        readonly IXsdService _xsdService;

        public MappingViewController(IDocItemReader docItemReader, IDbContext dbContext, IXsdService xsdService)
        {
            _docItemReader = docItemReader;
            _dbContext = dbContext;
            _xsdService = xsdService;
        }

        [HttpGet]
        [Route("mappingView/{id}")]
        public async Task<dynamic> Get(int id)
        {
            var docItems = new Dictionary<int, object>();

            var mapping = await _dbContext.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().SingleOrDefaultAsync(_ => _.Id == id);

            if (mapping == null)
                HttpResponseExceptionHelper.RaiseNotFound("Mapping not found: id=" + id);

            object schema;
            try
            {
                schema = _xsdService.Parse(mapping.SchemaPackage.Id,mapping.RootNode);
            }
            catch (MissingSchemaDependencyException ex)
            {
                return new { Id = id, mapping.Name, ex.MissingDependencies };
            }

            JObject mappingEntries = null;

            if (!string.IsNullOrWhiteSpace(mapping.Content))
            {
                mappingEntries = (JObject)JObject.Parse(mapping.Content)["mappingEntries"];

                if (mappingEntries != null)
                {
                    foreach (var pair in mappingEntries)
                    {
                        var docItemId = (int?)pair.Value.SelectToken("docItem.id");
                        if (docItemId == null)
                            continue;

                        docItems[docItemId.Value] = _docItemReader.Read(docItemId.Value);
                    }
                }
            }

            var rootObj = new RootNodeInfo().ParseJson(mapping.RootNode);
            return new
            {
                Id = id,
                mapping.Name,
                MappingEntries = mappingEntries,
                DocItems = docItems,
                Schema = schema,
                RootNodeName = rootObj.QualifiedName.Name,
                rootObj.IsDtdFile,
                FileRef = rootObj.IsDtdFile ? rootObj.FileRef : null,
                rootObj.FileName
            };
        }
    }
}
