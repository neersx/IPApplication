using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;

namespace Inprotech.IntegrationServer.PtoAccess.CleanUp
{
    public sealed class ScheduleExecutionSessionFolderCleaner : ICleanUpFolders
    {
        readonly IFileHelpers _fileHelpers;
        readonly IFileSystem _fileSystem;
        readonly IPublishFolderCleanUpEvents _publisher;

        public ScheduleExecutionSessionFolderCleaner(IFileHelpers fileHelpers, IFileSystem fileSystem, IPublishFolderCleanUpEvents publisher)
        {
            _fileHelpers = fileHelpers;
            _fileSystem = fileSystem;
            _publisher = publisher;
        }

        public Task Clean(Guid sessionGuid, string sessionRootPath)
        {
            var path = _fileSystem.AbsolutePath(sessionRootPath);
            if (_fileHelpers.DirectoryExists(path))
            {
                CleanSessionFolders(sessionGuid, path);
            }

            return Task.FromResult(0);
        }

        void CleanSessionFolders(Guid sessionGuid, string path)
        {
            if (string.IsNullOrEmpty(path)) throw new ArgumentNullException("path");

            try
            {
                foreach (var d in _fileHelpers.EnumerateDirectories(path))
                {
                    CleanSessionFolders(sessionGuid, d);
                }

                if (!_fileHelpers.EnumerateFileSystemEntries(path).Any())
                {
                    try
                    {
                        _fileSystem.DeleteFolder(path);
                        _publisher.Publish(sessionGuid, "Folder is empty", path);
                    }
                    catch (UnauthorizedAccessException)
                    {
                    }
                    catch (DirectoryNotFoundException)
                    {
                    }
                }
            }
            catch (UnauthorizedAccessException)
            {
            }
            catch (Exception ex)
            {
                _publisher.Publish(sessionGuid, "Folder is empty", path, ex);
                throw;
            }
        }
    }
}