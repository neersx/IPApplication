using System;
using System.IO;
using System.Xml.Linq;
using NLog;

namespace Inprotech.Setup.Core
{
    public interface IWebConfigBackupReader
    {
        WebConfigBackup Read(string basePath);
    }

    class WebConfigBackupReader : IWebConfigBackupReader
    {
        static readonly Logger Logger = LogManager.GetCurrentClassLogger();

        readonly IAuthenticationMode _authMode;
        readonly IFileSystem _fileSystem;

        public WebConfigBackupReader(IAuthenticationMode authMode, IFileSystem fileSystem)
        {
            _authMode = authMode;
            _fileSystem = fileSystem;
        }

        public string GetAuthenticationMode(string basePath)
        {
            var path = Path.Combine(basePath, Constants.InprotechBackup.Folder, Constants.InprotechBackup.WebConfig);
            if (!_fileSystem.FileExists(path))
                return string.Empty;

            var config = XElement.Load(path);

            return _authMode.ResolveFromBackupConfig(config);
        }

        public WebConfigBackup Read(string basePath)
        {
            var path = Path.Combine(basePath, Constants.InprotechBackup.Folder, Constants.InprotechBackup.WebConfig);

            try
            {
                var result = new WebConfigBackup {Exists = _fileSystem.FileExists(path)};

                if (!result.Exists)
                    return result;

                var config = XElement.Load(path);
                result.AuthenticationMode = _authMode.ResolveFromBackupConfig(config);
                return result;
            }
            catch (Exception ex)
            {
                Logger.Error(ex, $"backup of web.config location=\"{path}\".");

                return null;
            }
        }
    }
}