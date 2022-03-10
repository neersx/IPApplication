using System.IO;
using System.Security.AccessControl;
using System.Security.Principal;

namespace Inprotech.Tests.Integration.Utils
{
    public static class FileSetup
    {
        public static string MakeAvailable(string assetResourcePath)
        {
            var filePath = Path.Combine(Path.GetTempPath(), assetResourcePath);

            File.WriteAllText(filePath, From.EmbeddedAssets(assetResourcePath));

            return filePath;
        }

        public static string SendToStorage(string assetResourcePath, string name, string area, string storage = null)
        {
            storage = storage ?? Env.StorageLocation;

            var directory = Path.Combine(storage, area);

            if (!Directory.Exists(directory))
            {
                Directory.CreateDirectory(directory);
            }

            var filePath = Path.Combine(directory, name ?? assetResourcePath);

            File.WriteAllText(filePath, From.EmbeddedAssets(assetResourcePath));

            SetFilePermissionForEveryOne(filePath);

            return filePath;
        }

        static void SetFilePermissionForEveryOne(string filePath)
        {
            // Read the current ACL details for the file
            var fileSecurity = File.GetAccessControl(filePath);

            // Create a new rule set, based on "Everyone"
            var fileAccessRule = new FileSystemAccessRule(new NTAccount(string.Empty, "Everyone"),
                                                          FileSystemRights.FullControl,
                                                          AccessControlType.Allow);

            // Append the new rule set to the file
            fileSecurity.AddAccessRule(fileAccessRule);

            // And persist it to the filesystem
            File.SetAccessControl(filePath, fileSecurity);
        }

        public static void DeleteFile(string file)
        {
            Try.Do(() => File.Delete(file));
        }
    }
}