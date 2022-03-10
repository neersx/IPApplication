using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.SchemaMapping;
using Inprotech.Integration.SchemaMapping.Xsd;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.SchemaMappings;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.SchemaMapping
{
    [Authorize]
    [RoutePrefix("api/schemapackage")]
    [NoEnrichment]
    public class SchemaPackageController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly ISyncToTableCodes _syncToTableCodes;
        readonly IXsdService _xsdService;

        public SchemaPackageController(IDbContext dbContext, ISyncToTableCodes syncToTableCodes, Func<DateTime> now, IXsdService xsdService)
        {
            _dbContext = dbContext;
            _now = now;
            _xsdService = xsdService;
            _syncToTableCodes = syncToTableCodes;
        }

        [HttpGet]
        [Route("list")]
        public async Task<dynamic> List()
        {
            return await _dbContext.Set<SchemaPackage>()
                                   .OrderByDescending(_ => _.Id)
                                   .Select(_ => new
                                   {
                                       _.Id,
                                       _.Name,
                                       _.IsValid,
                                       UpdatedOn = _.LastModified
                                   })
                                   .ToArrayAsync();
        }

        [HttpPut]
        [Route("{packageId:int}/name")]
        [RequiresAccessTo(ApplicationTask.ConfigureSchemaMappingTemplate)]
        public async Task<dynamic> UpdateName(int packageId, JObject data)
        {
            var newName = data["name"].ToString();

            var validity = await IsPackageNameValid(newName, packageId);
            if (validity.Status != "Valid")
            {
                HttpResponseExceptionHelper.RaiseBadRequest(validity.Error);
            }

            var package = await _dbContext.Set<SchemaPackage>().SingleOrDefaultAsync(_ => _.Id == packageId);
            package.Name = newName;
            _dbContext.SaveChanges();

            return new
            {
                Status = "Success"
            };
        }

        [HttpGet]
        [Route("{packageId:int}/details")]
        [RequiresAccessTo(ApplicationTask.ConfigureSchemaMappingTemplate)]
        public async Task<dynamic> GetOrCreate(int packageId)
        {
            var package = _dbContext.Set<SchemaPackage>().SingleOrDefault(_ => _.Id == packageId);
            if (package == null)
            {
                return ReturnForNewSchemaPackage();
            }

            var files = await _dbContext.Set<SchemaFile>()
                                        .Where(_ => _.SchemaPackageId == packageId)
                                        .Select(_ =>
                                                    new
                                                    {
                                                        _.Id,
                                                        _.IsMappable,
                                                        MetadataId = _.Id,
                                                        _.Name,
                                                        _.SchemaPackageId,
                                                        UpdatedOn = _.LastModified
                                                    }).ToArrayAsync();

            var schemaInfo = _xsdService.Inspect(packageId);

            return new
            {
                Status = "SchemaPackageDetails",
                Package = package,
                Files = files,
                schemaInfo.MissingDependencies,
                Error = schemaInfo.SchemaError
            };
        }

        [HttpGet]
        [Route("{packageId:int}/roots")]
        public async Task<dynamic> GetPossibleRoots(int packageId)
        {
            var package = await _dbContext.Set<SchemaPackage>()
                                          .SingleOrDefaultAsync(_ => _.Id == packageId);
            if (package == null)
            {
                throw new Exception();
            }

            var schemaInfo = _xsdService.GetPossibleRootNodes(packageId);
            return new
            {
                Status = "RootNodes",
                Package = package,
                Nodes = schemaInfo.Select(_ => new
                                  {
                                      _.QualifiedName.Name,
                                      _.QualifiedName.Namespace,
                                      _.FileName,
                                      _.IsDtdFile
                                  })
                                  .ToArray()
            };
        }

        [HttpPost]
        [Route("{packageId:int}")]
        [RequiresAccessTo(ApplicationTask.ConfigureSchemaMappingTemplate)]
        public async Task<dynamic> Upload(int packageId, JObject data)
        {
            var xmlStr = (string) data["content"];
            var filename = (string) data["fileName"];
            var existingSchemaFile = await _dbContext.Set<SchemaFile>()
                                                     .SingleOrDefaultAsync(_ => _.Name == filename && _.SchemaPackageId == packageId);

            var exists = existingSchemaFile != null;
            return exists
                ? ReturnForFileExists(xmlStr, existingSchemaFile)
                : ReturnForNewSchemaFile(packageId, xmlStr, filename);
        }

        [HttpDelete]
        [Route("{packageId:int}/file/{fileid:int}")]
        [RequiresAccessTo(ApplicationTask.ConfigureSchemaMappingTemplate)]
        public async Task<dynamic> Delete(int packageId, int fileId)
        {
            using (var tx = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var schemaFile = await _dbContext.Set<SchemaFile>()
                                                 .SingleOrDefaultAsync(_ => _.Id == fileId && _.SchemaPackageId == packageId);

                _dbContext.Set<SchemaFile>().Remove(schemaFile);

                await _dbContext.SaveChangesAsync();

                _syncToTableCodes.Sync();

                await _dbContext.SaveChangesAsync();

                tx.Complete();
            }

            var schemaInfo = _xsdService.Inspect(packageId);

            return new
            {
                schemaInfo.MissingDependencies,
                Error = schemaInfo.SchemaError
            };
        }

        [HttpDelete]
        [Route("{packageId:int}")]
        public async Task Delete(int packageId)
        {
            using (var transaction = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var mappings = _dbContext.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().Where(_ => _.SchemaPackageId == packageId).ToList();

                var schemaFiles = _dbContext.Set<SchemaFile>()
                                            .Where(_ => _.SchemaPackageId.HasValue && _.SchemaPackageId.Value == packageId)
                                            .ToList();

                var schemaPackage = schemaFiles.Any()
                    ? schemaFiles.First().SchemaPackage
                    : await _dbContext.Set<SchemaPackage>().SingleOrDefaultAsync(_ => _.Id == packageId);

                mappings.ForEach(_ => _dbContext.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().Remove(_));

                schemaFiles.ForEach(_ => _dbContext.Set<SchemaFile>().Remove(_));

                _dbContext.Set<SchemaPackage>().Remove(schemaPackage);

                await _dbContext.SaveChangesAsync();

                _syncToTableCodes.Sync();

                await _dbContext.SaveChangesAsync();

                transaction.Complete();
            }
        }

        dynamic ReturnForFileExists(string xmlStr, SchemaFile existingSchemaFile)
        {
            var newSchemaFile = _dbContext.Set<SchemaFile>()
                                          .Add(new SchemaFile
                                          {
                                              Content = xmlStr,
                                              Name = existingSchemaFile.Name,
                                              SchemaPackageId = existingSchemaFile.SchemaPackageId
                                          });

            _dbContext.SaveChanges();

            return new
            {
                Status = "FileAlreadyExists",
                ContentsMatch = xmlStr == existingSchemaFile.Content,
                UploadedFileId = newSchemaFile.Id,
                ExistingFileId = existingSchemaFile.Id
            };
        }

        dynamic ReturnForNewSchemaFile(int packageId, string content, string filename)
        {
            var newSchemaFile = _dbContext.Set<SchemaFile>().Add(new SchemaFile
            {
                Content = content,
                Name = filename,
                SchemaPackageId = packageId
            });

            _dbContext.SaveChanges();

            var schemaInfo = _xsdService.Inspect(packageId);

            return new
            {
                Status = "SchemaFileCreated",
                SchemaFile = new
                {
                    newSchemaFile.Id,
                    newSchemaFile.Name,
                    UpdatedOn = _dbContext.Reload(newSchemaFile).LastModified
                },
                schemaInfo.MissingDependencies,
                Error = schemaInfo.SchemaError
            };
        }

        dynamic ReturnForNewSchemaPackage()
        {
            var currentDateTime = _now();
            var newname = $"NewSchemaPackage_{currentDateTime.Day}{currentDateTime.Month}{currentDateTime.Year}_";
            var count = _dbContext.Set<SchemaPackage>().Count(_ => _.Name.StartsWith(newname));

            var newSchemaPackage = new SchemaPackage
            {
                Name = newname + (count + 1),
                IsValid = false
            };

            newSchemaPackage = _dbContext.Set<SchemaPackage>().Add(newSchemaPackage);
            _dbContext.SaveChanges();

            return new
            {
                Status = "SchemaPackageCreated",
                Package = newSchemaPackage,
                Error = SchemaSetError.FilesRequired
            };
        }

        async Task<dynamic> IsPackageNameValid(string name, int packageId)
        {
            if (string.IsNullOrEmpty(name))
            {
                return new
                {
                    Status = "NameError",
                    Error = "MandatoryName"
                };
            }

            if (await _dbContext.Set<SchemaPackage>().CountAsync(_ => _.Name == name && _.Id != packageId) > 0)
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