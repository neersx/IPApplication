using System;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public interface IUpdateArtifactMessageIndex
    {
        Task<string> Update(byte[] artifact, string applicationId, string destinationLocation);
    }

    public class UpdateArtifactMessageIndex : IUpdateArtifactMessageIndex
    {
        readonly ICompressionHelper _compressionHelper;
        readonly Func<Guid> _keyGenerator;
        readonly IFileSystem _fileSystem;

        public UpdateArtifactMessageIndex(IFileSystem fileSystem, ICompressionHelper compressionHelper, Func<Guid> keyGenerator)
        {
            _fileSystem = fileSystem;
            _compressionHelper = compressionHelper;
            _keyGenerator = keyGenerator;
        }

        public async Task<string> Update(byte[] artifact, string nameId, string destinationLocation)
        {
            if (artifact == null) throw new ArgumentNullException(nameof(artifact));
            if (string.IsNullOrWhiteSpace(nameId)) throw new ArgumentException(nameof(nameId));
            if (string.IsNullOrWhiteSpace(destinationLocation)) throw new ArgumentException(nameof(destinationLocation));

            var zipFullPath = await _compressionHelper.CreateZipFile(artifact, $"recoverable_{nameId}_{_keyGenerator()}.zip");
            var nextFileNumber = _fileSystem.Files(destinationLocation, "*.json")
                                            .Select(f => int.TryParse(Path.GetFileNameWithoutExtension(f), out var index) ? index : 0)
                                            .Max() + 1;

            using (var archive = ZipFile.Open(zipFullPath, ZipArchiveMode.Update))
            {
                var zipFiles = archive.Entries.ToArray();

                foreach (var zipFile in zipFiles.Where(zf => zf.Name.EndsWith(".json")))
                {
                    if (int.TryParse(zipFile.Name, out var index))
                    {
                        var newEntry = archive.CreateEntry($"{(nextFileNumber + index).ToString()}.json");
                        using (var a = zipFile.Open())
                        using (var b = newEntry.Open())
                        {
                            await a.CopyToAsync(b);
                        }

                        zipFile.Delete();
                    }
                }
            }

            return zipFullPath;
        }
    }
}