using System;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Contracts.Storage;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.SchemaMappings;

namespace Inprotech.Web.SchemaMapping
{
    [Authorize]
    [RoutePrefix("api/storage")]
    [NoEnrichment]
    public class StorageController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IStorage _storage;

        public StorageController(IDbContext dbContext, IStorage storage)
        {
            _dbContext = dbContext;
            _storage = storage;
        }

        [HttpGet]
        [Route("{id}")]
        public async Task<HttpResponseMessage> Get(string id)
        {
            if (Guid.TryParse(id, out Guid storageId))
            {
                var metadata = await _storage.GetFileMetadata(storageId);
                var file = await _storage.Load(storageId);

                return HttpResponseMessageBuilder.File(metadata.Filename, file.Content);
            }

            if (int.TryParse(id, out int schemaFileId))
            {
                var schemaFile = await _dbContext.Set<SchemaFile>().SingleAsync(_ => _.Id == schemaFileId);

                return HttpResponseMessageBuilder.File(schemaFile.Name, schemaFile.Content);
            }

            return new HttpResponseMessage(HttpStatusCode.BadRequest);
        }
        
        [HttpDelete]
        [Route("{id:int}")]
        public async Task Delete(int id)
        {
            var schemaFile = await _dbContext.Set<SchemaFile>().SingleAsync(_ => _.Id == id);

            _dbContext.Set<SchemaFile>().Remove(schemaFile);

            await _dbContext.SaveChangesAsync();
        }

        [HttpPut]
        [Route("{id:int}")]
        public async Task<dynamic> Overwrite(int id, int withFileId)
        {
            var schemaFiles = _dbContext.Set<SchemaFile>()
                                        .Where(_ => _.Id == id || _.Id == withFileId)
                                        .ToDictionary(k => k.Id, v => v);

            _dbContext.Set<SchemaFile>().Remove(schemaFiles[id]);

            await _dbContext.SaveChangesAsync();
            
            return new { UploadedFileId = withFileId };
        }
    }
}