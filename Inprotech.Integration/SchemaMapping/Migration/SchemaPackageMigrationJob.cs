using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts.Storage;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.SchemaMapping.Migration.Models;
using Inprotech.Integration.SchemaMapping.Xsd;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.SchemaMappings;
using Newtonsoft.Json.Linq;
using Job = Inprotech.Integration.Jobs.Job;
using SchemaMappingModel = InprotechKaizen.Model.SchemaMappings.SchemaMapping;

namespace Inprotech.Integration.SchemaMapping.Migration
{
    public class SchemaPackageMigrationJob : IPerformBackgroundJob
    {
        readonly ISchemaPackageJobHandler _schemaHandler;

        public SchemaPackageMigrationJob(ISchemaPackageJobHandler schemaHandler)
        {
            _schemaHandler = schemaHandler;
        }

        public string Type => "SchemaPackageMigration";

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            return Activity.Run<SchemaPackageMigrationJob>(sm => sm.Run(jobExecutionId));
        }

        public async Task Run(long jobExecutionId)
        {
            await _schemaHandler.Run(Type);
        }
    }

    public interface ISchemaPackageJobHandler
    {
        Task Run(string jobName);
    }

    internal class SchemaPackageJobHandler : ISchemaPackageJobHandler
    {
        readonly IDbContext _dbContext;
        readonly IRepository _repository;
        readonly IStorage _storage;
        readonly ISyncToTableCodes _syncTableCodes;
        readonly IXsdService _xsdService;

        public SchemaPackageJobHandler(IDbContext dbContext, IRepository repository, IXsdService xsdService, IStorage storage, ISyncToTableCodes syncTableCodes)
        {
            _dbContext = dbContext;
            _repository = repository;
            _xsdService = xsdService;
            _storage = storage;
            _syncTableCodes = syncTableCodes;
        }

        public async Task Run(string jobName)
        {
            if (!_repository.Set<Job>().Any(_ => _.Type == jobName))
            {
                // This job is not availble.
                return;
            }

            if (_dbContext.Set<SchemaFile>().Any())
            {
                // There is already data in the destination table
                return;
            }

            await MigrateToNewStructure();

            await MigratePrePackageData();

            await DeleteOldData();

            _syncTableCodes.Sync();

            await _dbContext.SaveChangesAsync();
        }

        async Task DeleteOldData()
        {
            await _repository.DeleteAsync(_repository.Set<ObsoleteSchemaFile>());

            await _repository.DeleteAsync(_repository.Set<ObsoleteSchemaMapping>());

            await _repository.DeleteAsync(_repository.Set<ObsoleteSchemaPackage>());

            await _repository.SaveChangesAsync();
        }

        async Task MigrateToNewStructure()
        {
            var oldFiles = _repository.Set<ObsoleteSchemaFile>().ToArray();
            var oldMappings = _repository.Set<ObsoleteSchemaMapping>().ToArray();
            var oldPackages = _repository.Set<ObsoleteSchemaPackage>().ToArray();

            var newFiles = _dbContext.Set<SchemaFile>();
            var newMappings = _dbContext.Set<SchemaMappingModel>();
            var newPackages = _dbContext.Set<SchemaPackage>();

            foreach (var oldPackage in oldPackages)
            {
                newPackages.Add(new SchemaPackage
                {
                    IsValid = oldPackage.IsValid,
                    Name = oldPackage.Name
                });
            }

            await _dbContext.SaveChangesAsync();

            foreach (var oldSchemaFile in oldFiles)
            {
                var oldPackageName = oldSchemaFile.ObsoleteSchemaPackage?.Name;

                var newPackage = oldPackageName == null
                    ? null
                    : newPackages.Single(_ => _.Name == oldPackageName);

                newFiles.Add(new SchemaFile
                {
                    Name = oldSchemaFile.Name,
                    Content = await _storage.ReadAllText(oldSchemaFile.MetadataId),
                    IsMappable = oldSchemaFile.IsMappable,
                    SchemaPackage = newPackage
                });

                await _storage.Delete(oldSchemaFile.MetadataId);
            }
            
            await _dbContext.SaveChangesAsync();
            
            foreach (var oldMapping in oldMappings)
            {
                var oldPackageName = oldMapping.ObsoleteSchemaPackage?.Name;

                var newPackage = oldPackageName == null
                    ? null
                    : newPackages.Single(_ => _.Name == oldPackageName);

                newMappings.Add(new SchemaMappingModel
                {
                    Name = oldMapping.Name,
                    Content = oldMapping.Content,
                    RootNode = oldMapping.RootNode,
                    Version = oldMapping.Version,
                    SchemaPackage = newPackage
                });
            }

            await _dbContext.SaveChangesAsync();

            _syncTableCodes.Sync();

            await _dbContext.SaveChangesAsync();
        }

        async Task MigratePrePackageData()
        {
            var unmappedSchemaFiles = _dbContext.Set<SchemaFile>().Where(_ => _.SchemaPackageId == null).ToList();
            if (unmappedSchemaFiles.Count == 0) return;

            var schemaPackages = _dbContext.Set<SchemaPackage>().ToList();
            foreach (var schemaPackage in schemaPackages)
                await VerifyPackageDependencies(schemaPackage.Id, 1);

            _dbContext.Delete(_dbContext.Set<SchemaFile>().Where(_ => _.SchemaPackageId == null));

            await _dbContext.SaveChangesAsync();
        }

        async Task VerifyPackageDependencies(int packageId, int currentTries)
        {
            var schemaInfo = SafeCheckValidity(packageId);

            if (await IsValidSchemaPackage(packageId, schemaInfo)) return;

            if (!schemaInfo.MissingDependencies.Any() || currentTries > 100) return;

            var dependentFiles = _dbContext.Set<SchemaFile>()
                                           .Where(p => p.SchemaPackageId == null && schemaInfo.MissingDependencies.Contains(p.Name))
                                           .ToList();

            if (dependentFiles.Count == 0) return;

            foreach (var file in dependentFiles)
                CopyDependentFile(packageId, file);

            await _dbContext.SaveChangesAsync();

            await VerifyPackageDependencies(packageId, ++currentTries);
        }

        void CopyDependentFile(int packageId, SchemaFile file)
        {
            _dbContext.Set<SchemaFile>().Add(new SchemaFile
            {
                Name = file.Name,
                SchemaPackageId = packageId,
                Content = file.Content,
                IsMappable = file.IsMappable
            });
        }

        XsdMetadata SafeCheckValidity(int packageId)
        {
            try
            {
                return _xsdService.Inspect(packageId);
            }
            catch
            {
                return new XsdMetadata(SchemaSetError.ValidationError, new List<string>());
            }
        }

        string SafeGetNode(int packageId)
        {
            try
            {
                return _xsdService.GetPossibleRootNodes(packageId).First().ToJsonString();
            }
            catch
            {
                return string.Empty;
            }
        }

        async Task<bool> IsValidSchemaPackage(int packageId, XsdMetadata schemaInfo)
        {
            if (!schemaInfo.IsMappable) return false;

            SetRootNodeForMapping(packageId);

            var package = await _dbContext.Set<SchemaPackage>().SingleAsync(_ => _.Id == packageId);

            package.IsValid = true;

            await _dbContext.SaveChangesAsync();

            return true;
        }

        void SetRootNodeForMapping(int packageId)
        {
            var rootNodeJson = SafeGetNode(packageId);
            var mappings = _dbContext.Set<SchemaMappingModel>().Where(_ => _.SchemaPackageId == packageId);

            foreach (var mapping in mappings)
                mapping.RootNode = rootNodeJson;
        }
    }
}