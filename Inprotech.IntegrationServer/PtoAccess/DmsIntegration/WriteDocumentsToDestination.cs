using System;
using System.IO;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration.DmsIntegration;

namespace Inprotech.IntegrationServer.PtoAccess.DmsIntegration
{
    public interface IWriteDocumentAndMetadataToDestination
    {
        Task Write(Stream document, Stream metadata, string destinationFilePath);
    }

    public class WriteDocumentsToDestination : IWriteDocumentAndMetadataToDestination
    {
        readonly IFileHelpers _fileHelpers;

        public WriteDocumentsToDestination(IFileHelpers fileHelpers)
        {
            _fileHelpers = fileHelpers;
        }

        public async Task Write(Stream document, Stream metadata, string destinationFilePath)
        {
            if (document == null) throw new ArgumentNullException(nameof(document));
            if (metadata == null) throw new ArgumentNullException(nameof(metadata));
            var destinationMetadataFilePath = _fileHelpers.ChangeExtension(destinationFilePath, ".xml");

            if(_fileHelpers.Exists(destinationFilePath)) throw new FileAlreadyExistsException(destinationFilePath);

            try
            {
                var destinationPath = _fileHelpers.GetDirectoryName(destinationFilePath);
                if (destinationPath != null && !_fileHelpers.DirectoryExists(destinationPath))
                {
                    _fileHelpers.CreateDirectory(destinationPath);
                }

                using (var dest = _fileHelpers.OpenWrite(destinationFilePath))
                {
                    await document.CopyToAsync(dest);
                }

                using (var destMetadata = _fileHelpers.OpenWrite(destinationMetadataFilePath))
                {
                    await metadata.CopyToAsync(destMetadata);
                }
            }
            catch (Exception)
            {
                if (_fileHelpers.Exists(destinationFilePath))
                {
                    _fileHelpers.DeleteFile(destinationFilePath);
                }
                if (_fileHelpers.Exists(destinationMetadataFilePath))
                {
                    _fileHelpers.DeleteFile(destinationMetadataFilePath);
                } 
                throw;
            }
        }
    }
}
