using System.Data.Entity;
using System.Linq;
using System.Security;
using System.Threading.Tasks;
using System.Transactions;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.SchemaMapping;
using Inprotech.Integration.SchemaMapping.Data;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.SchemaMappings;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.SchemaMapping
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ConfigureSchemaMappingTemplate)]
    [RoutePrefix("api/schemamappings")]
    [NoEnrichment]
    public class MappingController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ISyncToTableCodes _syncToTableCodes;

        public MappingController(IDbContext dbContext, ISyncToTableCodes syncToTableCodes)
        {
            _dbContext = dbContext;
            _syncToTableCodes = syncToTableCodes;
        }

        [HttpGet]
        [Route("mappings")]
        public dynamic List()
        {
            var mappings = _dbContext
                .Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>()
                .OrderBy(_ => _.Name)
                .ToArray()
                .Select(_ => new
                {
                    _.Id,
                    _.Name,
                    _.SchemaPackageId,
                    SchemaPackageName = _.SchemaPackage.Name,
                    _.SchemaPackage.IsValid,
                    _.LastModified,
                    RootNode = new RootNodeInfo().ParseJson(_.RootNode)
                });
            return mappings;
        }

        [HttpPut]
        [Route("{id:int}")]
        public async Task Put(int id, JObject data)
        {
            using (var tx = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var mapping = await _dbContext.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().SingleOrDefaultAsync(_ => _.Id == id);

                if (mapping == null)
                {
                    HttpResponseExceptionHelper.RaiseNotFound("Mapping not found: id=" + id);
                    return;
                }

                var mappingNameChanged = (string) data["name"] != mapping.Name;
                if (mappingNameChanged)
                {
                    var validity = await IsMappingNameValid((string) data["name"]);

                    if (validity.Status != "Valid")
                    {
                        HttpResponseExceptionHelper.RaiseBadRequest(validity.Error);
                    }

                    mapping.Name = (string) data["name"];
                }

                var rootObj = new RootNodeInfo().ParseJson(mapping.RootNode);
                if (rootObj.IsDtdFile && data.TryGetValue("fileRef", out JToken fileRefToken))
                {
                    rootObj.FileRef = fileRefToken.Value<string>();
                    mapping.RootNode = rootObj.ToJsonString();
                }

                mapping.Content = data["mappings"].ToString();

                await _dbContext.SaveChangesAsync();

                _syncToTableCodes.Sync();

                await _dbContext.SaveChangesAsync();

                tx.Complete();
            }
        }

        [HttpDelete]
        [Route("{id:int}")]
        public async Task Delete(int id)
        {
            using (var tx = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var mapping = await _dbContext.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().SingleAsync(_ => _.Id == id);

                _dbContext.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().Remove(mapping);

                await _dbContext.SaveChangesAsync();

                _syncToTableCodes.Sync();

                await _dbContext.SaveChangesAsync();

                tx.Complete();
            }
        }

        [HttpPost]
        [Route("")]
        public async Task<dynamic> Post(JObject data)
        {
            var mappingName = (string) data["mappingName"];
            var schemaPackageId = (int) data["schemaPackageId"];
            var copyMappingFrom = (int?) data["copyMappingFrom"];
            var rootNode = data["rootNode"].ToString();

            return await ReturnForNewMapping(mappingName, schemaPackageId, rootNode, copyMappingFrom);
        }

        async Task<dynamic> ReturnForNewMapping(string newMappingName, int schemaPackageId, string rootNode, int? copyMappingFrom = null)
        {
            var result = await IsMappingNameValid(newMappingName);
            if (result.Status != "Valid")
            {
                return result;
            }

            var nodeInfo = new RootNodeInfo().ParseJson(rootNode);
            if (!string.IsNullOrEmpty(nodeInfo.FileRef))
            {
                nodeInfo.FileRef = SecurityElement.Escape(nodeInfo.FileRef);
            }
            var schema = await _dbContext.Set<SchemaPackage>().SingleAsync(_ => _.Id == schemaPackageId);
            var file = await _dbContext.Set<SchemaFile>().SingleAsync(_ => _.SchemaPackageId == schemaPackageId && _.Name == nodeInfo.FileName);

            if (!schema.IsValid || file == null)
            {
                return new
                {
                    Status = "NameError",
                    Error = "InvalidPackage"
                };
            }

            var newMapping = new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Version = Constants.MappingVersion,
                Name = newMappingName,
                SchemaPackageId = schemaPackageId,
                RootNode = nodeInfo.ToJsonString(),
                Content = copyMappingFrom.HasValue
                    ? (await _dbContext.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().SingleAsync(_ => _.Id == copyMappingFrom)).Content
                    : null
            };

            using (var tx = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                _dbContext.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().Add(newMapping);

                await _dbContext.SaveChangesAsync();

                _syncToTableCodes.Sync();

                await _dbContext.SaveChangesAsync();

                tx.Complete();
            }

            return new
            {
                Status = "MappingCreated",
                Mapping = new
                {
                    newMapping.Id,
                    newMapping.Name,
                    newMapping.SchemaPackageId,
                    SchemaPackageName = schema.Name,
                    schema.IsValid,
                    newMapping.RootNode,
                    _dbContext.Reload(newMapping).LastModified
                }
            };
        }

        async Task<dynamic> IsMappingNameValid(string mappingName)
        {
            if (string.IsNullOrEmpty(mappingName))
            {
                return new
                {
                    Status = "NameError",
                    Error = "MandatoryName"
                };
            }

            if (await _dbContext.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().AnyAsync(_ => _.Name == mappingName))
            {
                return new
                {
                    Status = "NameError",
                    Error = "DuplicateName"
                };
            }

            return new
            {
                Status = "Valid"
            };
        }
    }
}