using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Contracts.Storage;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.SchemaMapping;
using Inprotech.Integration.SchemaMapping.XmlGen;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.SchemaMapping
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ConfigureSchemaMappingTemplate)]
    public class XmlGenController : XmlGenBaseController
    {
        readonly IDbContext _dbContext;
        readonly IStorage _storage;
        readonly Func<Guid> _guidFactory;

        public XmlGenController(IXmlGenService xmlGenService, IDbContext dbContext, IStorage storage, Func<Guid> guidFactory) : base(xmlGenService)
        {
            _dbContext = dbContext;
            _storage = storage;
            _guidFactory = guidFactory;
        }

        [HttpGet]
        [Route("api/schemamappings/{mappingId}/xmlview")]
        public async Task<dynamic> Get(int mappingId)
        {
            var parameters = ResolveParameters();

            return await GetXmlResponse(mappingId, parameters);
        }

        [HttpGet]
        [Route("api/schemamappings/{mappingId}/xmldownload")]
        public async Task<dynamic> Download(int mappingId)
        {
            var mapping = _dbContext.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().Single(_ => _.Id == mappingId);
            var mappingName = mapping.Name;
            var parameters = ResolveParameters();
            var filename = BuildFilename(mappingName, parameters.Values);

            string xml;

            try
            {
                xml = Helpers.GetXml(await XmlGenService.Generate(mappingId, parameters));
            }
            catch (XmlGenException ex)
            {
                return XmlGenerationFailure(ex);
            }

            var fileId = _guidFactory();
            await _storage.SaveText(filename, Constants.TempFileGroup, fileId, xml);

            return fileId;
        }

        static string BuildFilename(string mappingName, IEnumerable<object> parameters)
        {
            var filename = string.Join("_", new []{mappingName}.Concat(parameters)) + ".xml";
            filename = Helpers.SanitiseFilename(filename);

            return filename;
        }
    }
}