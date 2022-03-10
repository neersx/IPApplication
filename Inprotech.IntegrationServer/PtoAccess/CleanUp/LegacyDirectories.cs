using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using Inprotech.Contracts;
using Inprotech.Infrastructure;

namespace Inprotech.IntegrationServer.PtoAccess.CleanUp
{
    public interface ILegacyDirectories
    {
        IEnumerable<string> Enumerate(DateTime before);
    }

    public class LegacyDirectories : ILegacyDirectories
    {
        readonly IStorageLocation _storageLocation;
        readonly IFileHelpers _fileHelpers;
        readonly IFileSystem _fileSystem;

        static readonly string[] LookupFolders = { "UsptoIntegration", "PtoIntegration", "Inprotech.IntegrationServer" };

        static readonly Regex GuidPattern = new Regex("[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", RegexOptions.Compiled);

        public LegacyDirectories(IStorageLocation storageLocation, IFileHelpers fileHelpers, IFileSystem fileSystem)
        {
            _storageLocation = storageLocation;
            _fileHelpers = fileHelpers;
            _fileSystem = fileSystem;
        }

        public IEnumerable<string> Enumerate(DateTime before)
        {
            var dirs = _fileHelpers.EnumerateDirectories(_storageLocation.Resolve());

            return dirs.Where(_ => IsForCleanUp(_) && IsCreatedBefore(_, before))
                .SelectMany(GetSessionFolders)
                .Select(_fileSystem.RelativeStorageLocationPath)
                .ToArray();                
        }

        IEnumerable<string> GetSessionFolders(string path)
        {
            var dirs = _fileHelpers.EnumerateDirectories(path, "*", SearchOption.AllDirectories);

            return dirs.Where(dir => GuidPattern.IsMatch(dir));
        }

        bool IsCreatedBefore(string path, DateTime date)
        {
            var file = _fileHelpers.GetFiles(path, "*", SearchOption.AllDirectories).FirstOrDefault();

            if (file == null)
                return false;

            return _fileHelpers.GetFileInfo(file).LastWriteTime < date;
        }

        static bool IsForCleanUp(string path)
        {
            return LookupFolders.Any(_ => path.EndsWith(_, StringComparison.OrdinalIgnoreCase));
        }
    }
}