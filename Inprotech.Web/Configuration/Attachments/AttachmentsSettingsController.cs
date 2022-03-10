using System;
using System.IdentityModel;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Configuration.Attachments
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/attachments/settings")]
    [RequiresAccessTo(ApplicationTask.ConfigureAttachmentsIntegration)]
    public class AttachmentsSettingsController : ApiController
    {
        readonly IFileHelpers _fileHelpers;
        readonly IAttachmentSettings _settings;
        readonly IStorageServiceClient _storageServiceClient;

        public AttachmentsSettingsController(IAttachmentSettings settings, IFileHelpers fileHelpers, IStorageServiceClient storageServiceClient)
        {
            _settings = settings;
            _fileHelpers = fileHelpers;
            _storageServiceClient = storageServiceClient;
        }

        [HttpPut]
        [Route("")]
        public async Task<UpdateResponseModel> Update(AttachmentSetting model)
        {
            if (model == null)
            {
                throw new ArgumentException(nameof(model));
            }

            foreach (var location in model.StorageLocations)
            {
                if (!IsValidPath(location.Path, model.NetworkDrives))
                {
                    return new UpdateResponseModel {InvalidPath = true};
                }
            }

            var duplicateLocations = model.StorageLocations.GroupBy(_ => _.Path).Where(g => g.Count() > 1).Select(sl => sl.Key);
            if (duplicateLocations.Any())
            {
                return new UpdateResponseModel {InvalidPath = true};
            }

            model.IsRestricted = true;
            await _settings.Save(model);

            return new UpdateResponseModel();
        }

        [HttpGet]
        [Route("refreshcache")]
        public async Task RefreshCache()
        {
            await _storageServiceClient.RefreshCache(Request, await _settings.Resolve());
        }

        [HttpPost]
        [Route("validatepath")]
        public bool ValidatePath(ValidatePathModel model)
        {
            if (string.IsNullOrEmpty(model?.Path)) throw new BadRequestException("Path");
            return IsValidPath(model.Path, model.NetworkDrives);
        }

        bool IsValidPath(string path, AttachmentSetting.NetworkDrive[] drives)
        {
            var isAbs = Uri.TryCreate(path, UriKind.Absolute, out var p);

            if (isAbs && !p.IsUnc)
            {
                var drive = _fileHelpers.GetPathRoot(path);
                if (_fileHelpers.DirectoryExists(drive))
                {
                    return CheckPathExists(path);
                }

                var networkDrive = drives?.FirstOrDefault(_ => drive.Contains(_.DriveLetter));
                if (networkDrive != null)
                {
                    return CheckPathExists(Path.Combine(networkDrive.UncPath, path.Replace(drive, string.Empty)));
                }
            }

            return CheckPathExists(path);
        }

        bool CheckPathExists(string path)
        {
            return _fileHelpers.FilePathValid(path) && _fileHelpers.DirectoryExists(path);
        }

        public class ValidatePathModel
        {
            public string Path { get; set; }
            public AttachmentSetting.NetworkDrive[] NetworkDrives { get; set; }
        }

        public class UpdateResponseModel
        {
            public bool InvalidPath { get; set; }
        }
    }
}