using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.AccessControl;
using System.Security.Principal;

namespace Inprotech.Setup
{
    //todo: move it to core and validate storage location for CLI
    public interface IValidationService
    {
        bool ValidateFolder(FolderValidationInput input, out ICollection<string> validationErrors);
    }

    public static class FolderValidationErrors
    {
        public const string DirectoryDoesNotExist = "The directory does not exist";
        public const string SharedDirectoryDoesNotExist = "The shared directory does not exist";
        public const string Required = "Required";
        public const string NoWritePermission = "The user does not have permission to write to this directory";
        public const string InvalidFolder = "Invalid file path";
        public const string PathShouldBeRooted = "Storage location must be an absolute path, such as c:\\Inprotech\\Storage or \\\\Inprotech\\Storage";
        public const string PathShouldNotBeSubdirectoryOfCurrent = "Cannot change location to a subdirectory";
        public const string PathShouldBeAccesssibleToAllNodes = "Multi-node configuration requires the Storage Folder to be the same and accessible by all nodes";
    }

    public class ValidationService : IValidationService
    {
        public bool ValidateFolder(FolderValidationInput input, out ICollection<string> validationErrors)
        {
            validationErrors = new List<string>();

            if (string.IsNullOrWhiteSpace(input.CurrentValue))
            {
                validationErrors.Add(FolderValidationErrors.Required);
                return false;
            }

            if (!Directory.Exists(input.CurrentValue))
            {
                var unc = false;
                try
                {
                    unc = new Uri(input.CurrentValue).IsUnc;
                }
                catch (UriFormatException)
                {
                }

                validationErrors.Add(unc
                                         ? FolderValidationErrors.SharedDirectoryDoesNotExist
                                         : FolderValidationErrors.DirectoryDoesNotExist);
                return false;
            }

            if (!Path.IsPathRooted(input.CurrentValue))
            {
                validationErrors.Add(FolderValidationErrors.PathShouldBeRooted);
                return false;
            }

            if (!string.IsNullOrWhiteSpace(input.OriginalValue)
                && input.OriginalValue != input.CurrentValue && input.CurrentValue.StartsWith(input.OriginalValue))
            {
                validationErrors.Add(FolderValidationErrors.PathShouldNotBeSubdirectoryOfCurrent);
                return false;
            }

            try
            {
                var acl = Directory.GetAccessControl(input.CurrentValue);
                var accessRules = acl.GetAccessRules(true, true, typeof(SecurityIdentifier));

                foreach (FileSystemAccessRule rule in accessRules)
                {
                    if ((FileSystemRights.Write & rule.FileSystemRights) != FileSystemRights.Write)
                    {
                        continue;
                    }

                    if (rule.AccessControlType == AccessControlType.Deny)
                    {
                        validationErrors.Add(FolderValidationErrors.NoWritePermission);
                    }
                }
            }
            catch
            {
                validationErrors.Add(FolderValidationErrors.InvalidFolder);
            }

            if (input.ShouldUseSharedPath)
            {
                try
                {
                    if (!new Uri(input.CurrentValue).IsUnc)
                    {
                        var directoryRoot = Directory.GetDirectoryRoot(input.CurrentValue);

                        var directoryRootInfo = new DirectoryInfo(directoryRoot);

                        var drive = DriveInfo.GetDrives()
                                             .SingleOrDefault(_ => _.RootDirectory.FullName == directoryRootInfo.FullName);

                        if (drive?.DriveType != DriveType.Network)
                        {
                            validationErrors.Add(FolderValidationErrors.PathShouldBeAccesssibleToAllNodes);
                            return false;
                        }
                    }
                }
                catch
                {
                    validationErrors.Add(FolderValidationErrors.InvalidFolder);
                }
            }

            return validationErrors.Count == 0;
        }

        public string GetDriveLetter(string path)
        {
            return Directory.GetDirectoryRoot(path).Replace(Path.DirectorySeparatorChar.ToString(), string.Empty);
        }
    }

    public class FolderValidationInput
    {
        public string CurrentValue { get; set; }

        public string OriginalValue { get; set; }

        public bool ShouldUseSharedPath { get; set; }
    }
}