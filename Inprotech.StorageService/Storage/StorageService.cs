using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.StorageService;
using Inprotech.Web.Configuration.Attachments;

namespace Inprotech.StorageService.Storage
{
    public interface IStorageService
    {
        Task RebuildDirectoryCaching(AttachmentSetting settings = null);
        Task<bool> ValidatePath(string path);
        Task<StorageDirectoryResponse> GetDirectoryFolders();
        Task<IEnumerable<StorageFile>> GetDirectoryFiles(string folderPath);
        Task<HttpResponseMessage> SaveFile(FileToUpload fileToUpload);
        Task<string> GetTranslatedFilePath(string filePath);
        Task<DirectoryValidationResult> ValidateDirectory(string path);
    }

    public class DirectoryValidationResult
    {
        public bool IsLinkedToStorageLocation { get; set; }
        public bool DirectoryExists { get; set; }
    }

    public class StorageService : IStorageService
    {
        readonly IFileHelpers _fileHelpers;
        readonly IFileTypeChecker _fileTypeChecker;
        readonly IStorageCache _storageCache;
        readonly IValidateHttpOrHttpsString _validateHttpOrHttpsString;

        public StorageService(IFileHelpers fileHelpers, IStorageCache storageCache, IValidateHttpOrHttpsString validateHttpOrHttpsString, IFileTypeChecker fileTypeChecker)
        {
            _fileHelpers = fileHelpers;
            _storageCache = storageCache;
            _validateHttpOrHttpsString = validateHttpOrHttpsString;
            _fileTypeChecker = fileTypeChecker;
        }

        public async Task RebuildDirectoryCaching(AttachmentSetting settings = null)
        {
            await _storageCache.RebuildEntireCache(settings);
        }

        public async Task<bool> ValidatePath(string path)
        {
            var settings = await _storageCache.GetExistingAttachmentSetting();
            if (settings == null) throw new ApplicationException("Attachment Setting is not defined");
            if (_validateHttpOrHttpsString.Validate(path))
            {
                return true;
            }

            var storageLocation = settings.GetStorageLocation(path);
            if (storageLocation == null) return false;

            var fullPath = settings.GetMappedNetworkPath(path);

            if (!_fileHelpers.Exists(fullPath)) return false;

            if (!storageLocation.IsExtensionAllowed(_fileHelpers.GetFileExtension(fullPath))) return false;

            return true;
        }

        public async Task<DirectoryValidationResult> ValidateDirectory(string path)
        {
            var settings = await _storageCache.GetExistingAttachmentSetting();
            if (settings == null) throw new ApplicationException("Attachment Setting is not defined");

            if (!path.EndsWith(@"\"))
            {
                path = $"{path}\\";
            }

            var storageLocation = settings.GetStorageLocation(path);
            if (storageLocation == null)
            {
                return new DirectoryValidationResult { DirectoryExists = false, IsLinkedToStorageLocation = false };
            }

            var fullPath = settings.GetMappedNetworkPath(path);

            if (!_fileHelpers.DirectoryExists(fullPath))
            {
                return new DirectoryValidationResult { DirectoryExists = false, IsLinkedToStorageLocation = true };
            }

            return new DirectoryValidationResult { DirectoryExists = true, IsLinkedToStorageLocation = true };
        }

        public async Task<StorageDirectoryResponse> GetDirectoryFolders()
        {
            var result = new StorageDirectoryResponse { Folders = (await _storageCache.FetchFolders()).Select(MapStorageDirectory) };

            return result;
        }

        public async Task<IEnumerable<StorageFile>> GetDirectoryFiles(string folderPath)
        {
            return await _storageCache.FetchFilePaths(folderPath);
        }

        public async Task<HttpResponseMessage> SaveFile(FileToUpload fileToUpload)
        {
            if (string.IsNullOrEmpty(fileToUpload.FolderPath))
            {
                throw new ArgumentNullException(nameof(fileToUpload.FolderPath));
            }

            if (string.IsNullOrEmpty(fileToUpload.FileName))
            {
                throw new ArgumentNullException(nameof(fileToUpload.FileName));
            }

            if (fileToUpload.FileBytes == null)
            {
                throw new ArgumentNullException(nameof(fileToUpload.FileBytes));
            }

            if (fileToUpload.FileBytes.Length > 4194304)
            {
                ReturnBadRequest("File size exceeded");
            }

            var settings = await _storageCache.GetExistingAttachmentSetting();
            if (settings == null)
            {
                ReturnBadRequest("Attachment Setting is not defined");
            }

            var storageLocation = settings.GetStorageLocation(fileToUpload.FolderPath);
            if (storageLocation == null)
            {
                ReturnBadRequest("Invalid folder path");
            }

            var uncFolderPath = settings.GetMappedNetworkPath(fileToUpload.FolderPath);
            var filePath = Path.Combine(uncFolderPath, fileToUpload.FileName.Replace("\"", string.Empty));

            filePath = Path.Combine(uncFolderPath, Path.GetFileName(filePath));

            if (!storageLocation.IsExtensionAllowed(_fileHelpers.GetFileExtension(filePath)))
            {
                ReturnBadRequest("Invalid File Extension");
            }

            using (var fs = new MemoryStream(fileToUpload.FileBytes))
            {
                var extractedExtn = _fileTypeChecker.GetFileType(fs).Extension;

                if (extractedExtn == FileTypeExtension.WindowsDosExecutableFile)
                {
                    ReturnBadRequest("Invalid File Extension");
                }
            }

            await SaveFile(filePath, fileToUpload.FileBytes);

            return new HttpResponseMessage(HttpStatusCode.OK);
        }

        public async Task<string> GetTranslatedFilePath(string filePath)
        {
            var folderPath = Path.GetDirectoryName(filePath);
            var fileName = Path.GetFileName(filePath);
            var file = await _storageCache.GetFileDirectory(folderPath);
            if (file != null && !string.IsNullOrWhiteSpace(fileName))
            {
                var settings = await _storageCache.GetExistingAttachmentSetting();
                var cachedFolderName = file.Path;

                var networkDrive = settings.NetworkDrives.FirstOrDefault(n => cachedFolderName.IndexOf(n.DriveLetter + ":", StringComparison.InvariantCultureIgnoreCase) > -1);
                if (networkDrive != null)
                {
                    cachedFolderName = file.Path.Replace($"{networkDrive.DriveLetter}:\\", networkDrive.UncPath.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar) + Path.DirectorySeparatorChar);
                }

                var translatedFilePath = Path.Combine(cachedFolderName, fileName);
                return translatedFilePath;
            }

            return null;
        }

        async Task SaveFile(string filePath, byte[] data)
        {
            using (var fs = new MemoryStream(data))
            {
                if (!_fileHelpers.Exists(filePath))
                {
                    _fileHelpers.CreateFileDirectory(filePath);

                }
                using (var dest = _fileHelpers.OpenWrite(filePath))
                {
                    await fs.CopyToAsync(dest);
                }
            }
        }

        static void ReturnBadRequest(string message)
        {
            var resp = new HttpResponseMessage(HttpStatusCode.BadRequest)
            {
                Content = new StringContent(message),
                ReasonPhrase = message
            };

            throw new HttpResponseException(resp);
        }

        static StorageDirectory MapStorageDirectory(FilePathModel folder)
        {
            return new StorageDirectory
            {
                PathShortName = folder.PathShortName,
                FullPath = folder.Path,
                LowerFullPath = folder.Path.ToLower(),
                HasSubfolders = folder.SubFolders.Any(),
                Folders = folder.SubFolders.Select(MapStorageDirectory)
            };
        }
    }

    public class StorageDirectoryResponse
    {
        public IEnumerable<StorageDirectory> Folders { get; set; }
        public IEnumerable<string> Errors { get; set; }
    }

    public class StorageDirectory
    {
        public string PathShortName { get; set; }

        public string FullPath { get; set; }
        public string LowerFullPath { get; set; }
        public bool HasSubfolders { get; set; }

        public IEnumerable<StorageDirectory> Folders { get; set; }
    }

    public class StorageFile
    {
        public string PathShortName { get; set; }
        public string Type { get; set; }
        public string FullPath { get; set; }
        public DateTime DateModified { get; set; }
        public string Size { get; set; }
    }

    public class FileToUpload
    {
        public string FolderPath { get; set; }
        public string FileName { get; set; }
        public byte[] FileBytes { get; set; }
    }
}