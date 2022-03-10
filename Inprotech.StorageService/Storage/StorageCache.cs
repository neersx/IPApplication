using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.DependencyInjection;
using Inprotech.Web.Configuration.Attachments;

namespace Inprotech.StorageService.Storage
{
    public interface IStorageCache
    {
        Task<AttachmentSetting> GetExistingAttachmentSetting();
        Task RebuildEntireCache(AttachmentSetting settings = null);
        Task PopulateCache(string subDirectory);
        Task<IEnumerable<FilePathModel>> FetchFolders();
        Task<IEnumerable<StorageFile>> FetchFilePaths(string folderPath);
        Task<FilePathModel> GetFileDirectory(string folderPath);
    }

    public class StorageCache : IStorageCache
    {
        static readonly char[] SeparatorChars = {Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar};
        readonly IFileHelpers _fileHelpers;
        readonly ILifetimeScope _lifetimeScope;
        readonly IBackgroundProcessLogger<StorageCache> _logger;
        readonly IRecursivelySearchForPathInCache _recursivelySearchForPathInCache;
        readonly ConcurrentBag<FilePathModel> _topLevelNodes = new ConcurrentBag<FilePathModel>();
        readonly ConcurrentBag<FileSystemWatcher> _watchers = new ConcurrentBag<FileSystemWatcher>();
        AttachmentSetting _existingAttachmentSetting;
        int _foldersBeingMapped;

        public StorageCache(IFileHelpers fileHelpers, IRecursivelySearchForPathInCache recursivelySearchForPathInCache, ILifetimeScope lifetimeScope, IBackgroundProcessLogger<StorageCache> logger)
        {
            _fileHelpers = fileHelpers;
            _recursivelySearchForPathInCache = recursivelySearchForPathInCache;
            _lifetimeScope = lifetimeScope;
            _logger = logger;
        }

        public bool Initialized { get; private set; }

        public int FoldersBeingMapped => _foldersBeingMapped;

        public async Task PopulateCache(string subDirectory)
        {
            var settings = await GetExistingAttachmentSetting();
            var networkDrive = settings.NetworkDrives.FirstOrDefault(_ => subDirectory.Contains(_.UncPath));
            if (networkDrive != null)
            {
                subDirectory = subDirectory.Replace(networkDrive.UncPath, $"{networkDrive.DriveLetter}:");
            }

            var topLevel = await _recursivelySearchForPathInCache.RecursivelySearchInCache(subDirectory, _topLevelNodes);
            if (topLevel != null)
            {
                var path = topLevel.Path;
                if (networkDrive != null)
                {
                    path = subDirectory.Replace($"{networkDrive.DriveLetter}:\\", networkDrive.UncPath.TrimEnd(SeparatorChars) + Path.DirectorySeparatorChar);
                }

                topLevel.SubFolders = _fileHelpers.EnumerateDirectories(path).Select(_ => MapLocation(_, Path.GetFileName(_), null)).ToList();
            }
        }

        public async Task<IEnumerable<FilePathModel>> FetchFolders()
        {
            return _topLevelNodes.OrderBy(_ => _.PathShortName).ToList();
        }

        public async Task<IEnumerable<StorageFile>> FetchFilePaths(string folderPath)
        {
            var topFolder = await _recursivelySearchForPathInCache.RecursivelySearchInCache(folderPath, _topLevelNodes);
            if (topFolder == null)
            {
                return new List<StorageFile>();
            }

            var settings = await GetExistingAttachmentSetting();
            var fullPath = topFolder.Path;

            var storageLocation = settings.StorageLocations.SingleOrDefault(_ => topFolder.Path.ToLowerInvariant().IndexOf(_.Path.ToLowerInvariant(), StringComparison.Ordinal) == 0);
            if (storageLocation == null)
            {
                return new List<StorageFile>();
            }

            var mappedDrive = settings.NetworkDrives.SingleOrDefault(n => topFolder.Path.IndexOf(n.DriveLetter + ":", StringComparison.InvariantCultureIgnoreCase) > -1);
            if (mappedDrive != null)
            {
                fullPath = Path.Combine(mappedDrive.UncPath, topFolder.Path.Replace($"{mappedDrive.DriveLetter}:\\", string.Empty));
            }

            var files = _fileHelpers.GetFileInfos(fullPath).Where(f => !string.IsNullOrWhiteSpace(f.Extension) && storageLocation.IsExtensionAllowed(f.Extension.Substring(1)));
            return files.OrderBy(_ => _.Name).Select(_ => new StorageFile {PathShortName = _.Name, FullPath = FormatFileName(mappedDrive, _.FullName), DateModified = _.LastWriteTimeUtc, Type = _.Extension, Size = Math.Round((decimal) _.Length / 1024) + "kb"});
        }

        public async Task<FilePathModel> GetFileDirectory(string folderPath)
        {
            var directory = await _recursivelySearchForPathInCache.RecursivelySearchInCache(folderPath, _topLevelNodes);
            return directory;
        }

        public async Task RebuildEntireCache(AttachmentSetting newlyUpdatedSettings = null)
        {
            var existingSettings = _existingAttachmentSetting;
            if (newlyUpdatedSettings == null)
            {
                newlyUpdatedSettings = await GetExistingAttachmentSetting();
            }

            if (existingSettings != null)
            {
                RemoveRemovedPaths(existingSettings, newlyUpdatedSettings);
                AddNewlyCreatedPaths(newlyUpdatedSettings, existingSettings);
                UpdateTopLevelFolderNames(newlyUpdatedSettings);
            }
            else
            {
                if (newlyUpdatedSettings != null)
                {
                    foreach (var location in newlyUpdatedSettings.StorageLocations)
                    {
                        try
                        {
                            AddLocationToCache(newlyUpdatedSettings, location);
                        }
                        catch (Exception e)
                        {
                            _logger.Exception(e);
                        }
                    }

                    Initialized = true;
                }
            }

            SetExistingAttachmentSetting(newlyUpdatedSettings);
        }

        public async Task<AttachmentSetting> GetExistingAttachmentSetting()
        {
            if (_existingAttachmentSetting == null)
            {
                _existingAttachmentSetting = await RetrieveDatabaseAttachmentSetting();
            }

            return _existingAttachmentSetting;
        }

        async Task<AttachmentSetting> RetrieveDatabaseAttachmentSetting()
        {
            using (var scope = _lifetimeScope.BeginLifetimeScope())
            {
                var attachmentSettings = scope.Resolve<IAttachmentSettings>();
                return await attachmentSettings.Resolve();
            }
        }

        void SetExistingAttachmentSetting(AttachmentSetting setting)
        {
            _existingAttachmentSetting = setting;
        }

        public void RemoveExistingWatchers()
        {
            foreach (var fileSystemWatcher in _watchers)
            {
                fileSystemWatcher.EnableRaisingEvents = false;
                fileSystemWatcher.Dispose();
            }

            while (!_watchers.IsEmpty) _watchers.TryTake(out _);
        }

        async Task RemoveFolderFromCachedDirectory(string fullPath)
        {
            var subfolderToBeRemoved = Path.GetFileName(fullPath) ?? string.Empty;
            var parentFolderName = Path.GetDirectoryName(fullPath) ?? string.Empty;
            var settings = await GetExistingAttachmentSetting();
            var networkDrive = settings.NetworkDrives.FirstOrDefault(_ => parentFolderName.Contains(_.UncPath));
            var cachedFolderName = parentFolderName;
            if (networkDrive != null)
            {
                cachedFolderName = parentFolderName.Replace(networkDrive.UncPath, $"{networkDrive.DriveLetter}:");
            }

            var topLevel = await _recursivelySearchForPathInCache.RecursivelySearchInCache(cachedFolderName, _topLevelNodes);
            if (topLevel != null)
            {
                subfolderToBeRemoved = Path.Combine(parentFolderName, subfolderToBeRemoved).TrimEnd(SeparatorChars) + Path.DirectorySeparatorChar;
                topLevel.SubFolders = topLevel.SubFolders.Where(_ => _.Path != subfolderToBeRemoved);
            }
        }

        async Task AddFolderAndAllSubfoldersToCachedDirectory(string fullPath)
        {
            var subfolderName = Path.GetFileName(fullPath) ?? string.Empty;
            var parentFolderName = Path.GetDirectoryName(fullPath) ?? string.Empty;
            var settings = await GetExistingAttachmentSetting();
            var networkDrive = settings.NetworkDrives.FirstOrDefault(_ => parentFolderName.Contains(_.UncPath));
            var cachedFolderName = parentFolderName;
            if (networkDrive != null)
            {
                cachedFolderName = parentFolderName.Replace(networkDrive.UncPath.TrimEnd(SeparatorChars) + Path.DirectorySeparatorChar, $"{networkDrive.DriveLetter}:\\");
            }

            var topLevel = await _recursivelySearchForPathInCache.RecursivelySearchInCache(cachedFolderName, _topLevelNodes);
            if (topLevel != null)
            {
                var subFolderFullyQualifiedPath = Path.Combine(parentFolderName, subfolderName).TrimEnd(SeparatorChars) + Path.DirectorySeparatorChar;
                var newSubfolder = MapLocation(subFolderFullyQualifiedPath, subfolderName, networkDrive);
                topLevel.SubFolders = topLevel.SubFolders.Union(new[] {newSubfolder});
            }
        }

        void UpdateTopLevelFolderNames(AttachmentSetting newlyUpdatedSettings)
        {
            foreach (var location in newlyUpdatedSettings.StorageLocations)
            {
                var mappedDrive = MappedNetworkDrive(newlyUpdatedSettings, location);
                var path = location.Path;
                if (mappedDrive != null)
                {
                    path = Path.Combine(mappedDrive.UncPath, location.Path.Replace($"{mappedDrive.DriveLetter}:\\", string.Empty));
                }

                path = path.TrimEnd(SeparatorChars) + Path.DirectorySeparatorChar;

                var node = _topLevelNodes.FirstOrDefault(_ => _.Path == path || _.Path == location.Path);
                if (node != null)
                {
                    node.PathShortName = location.Name;
                }
            }
        }

        void RemoveRemovedPaths(AttachmentSetting existingSettings, AttachmentSetting newlyUpdatedSettings)
        {
            var storageLocationsToRemove = MappedPathNotIn(existingSettings, newlyUpdatedSettings);
            var pathsToRemove = storageLocationsToRemove.Select(_ => MappedNetworkPath(_, existingSettings)).ToList();
            var keptPaths = new List<FilePathModel>();
            RemoveExistingWatchers();
            if (pathsToRemove.Any())
            {
                while (!_topLevelNodes.IsEmpty)
                {
                    _topLevelNodes.TryTake(out var topLevelNode);
                    if (!pathsToRemove.Contains(existingSettings.GetMappedNetworkPath(topLevelNode.Path)))
                    {
                        keptPaths.Add(topLevelNode);
                    }
                }

                foreach (var filePathModel in keptPaths)
                {
                    _topLevelNodes.Add(filePathModel);
                    var path = filePathModel.Path;
                    var networkDrive = newlyUpdatedSettings.NetworkDrives.FirstOrDefault(_ => path.StartsWith(_.DriveLetter + ":" + Path.DirectorySeparatorChar));
                    if (networkDrive != null)
                    {
                        path = path.Replace($"{networkDrive.DriveLetter}:\\", networkDrive.UncPath);
                    }

                    WatchLocation(path);
                }
            }
        }

        void AddNewlyCreatedPaths(AttachmentSetting newlyUpdatedSettings, AttachmentSetting existingSettings)
        {
            var newStorageLocations = MappedPathNotIn(newlyUpdatedSettings, existingSettings);
            foreach (var newStorageLocation in newStorageLocations) AddLocationToCache(newlyUpdatedSettings, newStorageLocation);
        }

        static List<AttachmentSetting.StorageLocation> MappedPathNotIn(AttachmentSetting existingSettings, AttachmentSetting newlyUpdatedSettings)
        {
            return existingSettings.StorageLocations.Where(_ =>
            {
                var existingLocationPath = MappedNetworkPath(_, existingSettings);
                return !newlyUpdatedSettings.StorageLocations.Any(newStorageLocations =>
                {
                    var newLocationPath = MappedNetworkPath(newStorageLocations, newlyUpdatedSettings);
                    return newLocationPath.Equals(existingLocationPath);
                });
            }).ToList();
        }

        void AddLocationToCache(AttachmentSetting newlyUpdatedSettings, AttachmentSetting.StorageLocation location)
        {
            var mappedDrive = MappedNetworkDrive(newlyUpdatedSettings, location);
            var mappedPath = location.Path;
            if (mappedDrive != null)
            {
                mappedPath = Path.Combine(mappedDrive.UncPath, location.Path.Replace($"{mappedDrive.DriveLetter}:\\", string.Empty));
            }

            var newLocation = MapLocation(mappedPath, location.Name, mappedDrive);
            if (newLocation != null)
            {
                _topLevelNodes.Add(newLocation);
            }

            WatchLocation(location.Path);
        }

        static string MappedNetworkPath(AttachmentSetting.StorageLocation location, AttachmentSetting setting)
        {
            var path = location.Path;
            var mappedDrive = MappedNetworkDrive(setting, location);
            if (mappedDrive != null)
            {
                path = Path.Combine(mappedDrive.UncPath, path.Replace($"{mappedDrive.DriveLetter}:\\", string.Empty));
            }

            return path.TrimEnd(SeparatorChars) + Path.DirectorySeparatorChar;
        }

        static AttachmentSetting.NetworkDrive MappedNetworkDrive(AttachmentSetting newlyUpdatedSettings, AttachmentSetting.StorageLocation location)
        {
            var mappedDrive = newlyUpdatedSettings.NetworkDrives.SingleOrDefault(n => location.Path.IndexOf(n.DriveLetter + ":", StringComparison.InvariantCultureIgnoreCase) > -1);
            return mappedDrive;
        }

        string FormatFileName(AttachmentSetting.NetworkDrive networkDrive, string path)
        {
            return networkDrive == null ? path : Path.Combine($"{networkDrive.DriveLetter}:\\", path.Replace(networkDrive.UncPath.TrimEnd(SeparatorChars) + Path.DirectorySeparatorChar, string.Empty));
        }

        void WatchLocation(string path)
        {
            if (_fileHelpers.DirectoryExists(path))
            {
                var fileSystemWatcher = new FileSystemWatcher {Path = path, NotifyFilter = NotifyFilters.DirectoryName, IncludeSubdirectories = true, Filter = "*.*"};
                fileSystemWatcher.Changed += (target, eventArgs) => PopulateCache(Path.GetDirectoryName(eventArgs.FullPath));
                fileSystemWatcher.Created += (target, eventArgs) => AddFolderAndAllSubfoldersToCachedDirectory(eventArgs.FullPath);
                fileSystemWatcher.Renamed += (target, eventArgs) =>
                {
                    RemoveFolderFromCachedDirectory(eventArgs.OldFullPath);
                    AddFolderAndAllSubfoldersToCachedDirectory(eventArgs.FullPath);
                };
                fileSystemWatcher.Deleted += (target, eventArgs) => RemoveFolderFromCachedDirectory(eventArgs.FullPath);
                fileSystemWatcher.EnableRaisingEvents = true;
                _watchers.Add(fileSystemWatcher);
            }
        }

        FilePathModel MapLocation(string path, string shortName, AttachmentSetting.NetworkDrive drive)
        {
            var replacedPath = path.TrimEnd(SeparatorChars) + Path.DirectorySeparatorChar;
            if (drive != null)
            {
                replacedPath = Path.Combine($"{drive.DriveLetter}:{Path.DirectorySeparatorChar}", (path.TrimEnd(SeparatorChars) + Path.DirectorySeparatorChar).Replace(drive.UncPath.TrimEnd(SeparatorChars) + Path.DirectorySeparatorChar, string.Empty));
            }

            var newLocation = new FilePathModel
            {
                Path = replacedPath,
                PathShortName = shortName
            };

            Interlocked.Increment(ref _foldersBeingMapped);
            Task.Run(async () => { newLocation.SubFolders = _fileHelpers.EnumerateDirectories(path).OrderBy(_ => _).Select(_ => MapLocation(_, Path.GetFileName(_), drive)).ToList(); }).ContinueWith(_ => { Interlocked.Decrement(ref _foldersBeingMapped); });

            return newLocation;
        }
    }
}