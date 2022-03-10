using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Integration;
using Inprotech.Integration.CaseFiles;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Storage;

namespace Inprotech.IntegrationServer.PtoAccess.CleanUp
{
    public class ScheduleExecutionSessionCleaner : ICleanScheduleExecutionSessions
    {
        const int ChunkSize = 500;

        readonly IFileHelpers _fileHelpers;
        readonly IFileSystem _fileSystem;
        readonly IRepository _repository;
        readonly IPublishFileCleanUpEvents _publisher;

        public ScheduleExecutionSessionCleaner(IFileHelpers fileHelpers, IFileSystem fileSystem, IRepository repository, IPublishFileCleanUpEvents publisher)
        {
            _fileSystem = fileSystem;
            _fileHelpers = fileHelpers;
            _repository = repository;
            _publisher = publisher;
        }

        public Task Clean(Guid sessionGuid, string rootPath)
        {
            CleanSessionFiles(sessionGuid, rootPath);
            return Task.FromResult(0);
        }

        void CleanSessionFiles(Guid sessionGuid, string rootPath)
        {
            var absoluteRootPath = _fileSystem.AbsolutePath(rootPath);

            // get all the files in this folder tree and check that they have matching records in
            // filestores table, delete them if they don't
            if (!_fileHelpers.DirectoryExists(absoluteRootPath)) return;

            var files = _fileHelpers
                .GetFiles(absoluteRootPath, "*.*", SearchOption.AllDirectories)
                .Select(f => new PhysicalFile
                             {
                                 FileStorePath = _fileSystem.RelativeStorageLocationPath(f),
                                 FullPath = f
                             }).ToArray();

            var fileStores = _repository.Set<FileStore>();
            var caseFiles = _repository.Set<Case>();
            var documentFiles = _repository.Set<Document>();
            var otherCaseFiles = _repository.Set<CaseFiles>();

            // orphan files are files that don't have a filestore record, or that have a filestore record that is not
            // referenced by a case or document or caseFile record.
            var fileStorePaths = files.Select(f => f.FileStorePath).ToArray();
            var fileStoreRecords = new List<InterimFileRecords>();

            var currentSet = fileStorePaths.Take(ChunkSize).ToArray();
            var remainingSet = fileStorePaths.Except(currentSet).ToArray();
            while (currentSet.Any())
            {
                // batch the queries so that we don't timeout and 
                // there is no Out-of-memory exceptions.
                var matching = (from f in fileStores
                                where currentSet.Contains(f.Path)
                                select new InterimFileRecords
                                       {
                                           Id = f.Id,
                                           Path = f.Path,
                                           Referenced =
                                               caseFiles.Any(_ => _.FileStore != null && _.FileStore.Id == f.Id) ||
                                               documentFiles.Any(_ => _.FileStore != null && _.FileStore.Id == f.Id) ||
                                               otherCaseFiles.Any(_ => _.FileStore != null && _.FileStore.Id == f.Id)
                                       }).ToArray();

                fileStoreRecords.AddRange(matching);
                currentSet = remainingSet.Take(ChunkSize).ToArray();
                remainingSet = remainingSet.Except(currentSet).ToArray();
            }

            var unreferencedIds = new List<int>();
            var filesWithFileStoreRecords = (from fs in files
                                             join db in fileStoreRecords on fs.FileStorePath equals db.Path into dbj
                                             from db in dbj.DefaultIfEmpty()
                                             where db != null
                                             select new FileAndFileRecord
                                                    {
                                                        FileRecord = db,
                                                        FullPath = fs.FullPath
                                                    }).ToArray();

            foreach (var fileToDelete in files)
            {
                if (filesWithFileStoreRecords.Any(fs => fs.FileRecord.Path == fileToDelete.FileStorePath))
                    continue;

                Delete(fileToDelete.FullPath, sessionGuid, "File has no matching FileStore record");
            }

            foreach (var fileToDelete in filesWithFileStoreRecords)
            {
                if (fileToDelete.FileRecord.Referenced)
                    continue;

                unreferencedIds.Add(fileToDelete.FileRecord.Id);
                Delete(fileToDelete.FullPath, sessionGuid, $"File has a FileStore record (id: {fileToDelete.FileRecord.Id}) that is unreferenced");
            }

            if (!unreferencedIds.Any())
                return;

            _repository.Delete(fileStores.Where(_ => unreferencedIds.Contains(_.Id)));
        }

        void Delete(string path, Guid sessionGuid, string reason)
        {
            if (!_fileHelpers.Exists(path)) return;

            try
            {
                _fileHelpers.DeleteFile(path);
                _publisher.Publish(sessionGuid, reason, path);
            }
            catch (Exception ex)
            {
                if (!_fileHelpers.Exists(path))
                    return;

                _publisher.Publish(sessionGuid, reason, path, ex);
                throw;
            }
        }

        class FileAndFileRecord
        {
            public InterimFileRecords FileRecord { get; set; }

            public string FullPath { get; set; }
        }

        class InterimFileRecords
        {
            public int Id { get; set; }

            public string Path { get; set; }

            public bool Referenced { get; set; }
        }

        class PhysicalFile
        {
            public string FileStorePath { get; set; }

            public string FullPath { get; set; }
        }
    }
}