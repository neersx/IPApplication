using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Integration.Documents;

namespace Inprotech.IntegrationServer.PtoAccess.DmsIntegration
{
    public interface IResolveStorageLocationForPtoAccessDocument
    {
        string Resolve(Document document);
    }

    public class PtoAccessDocumentLocationResolver : IResolveStorageLocationForPtoAccessDocument
    {
        readonly IFileSystem _fileSystem;
        readonly IFileHelpers _fileHelpers;

        public PtoAccessDocumentLocationResolver(IFileSystem fileSystem, IFileHelpers fileHelpers)
        {
            _fileSystem = fileSystem;
            _fileHelpers = fileHelpers;
        }

        public string Resolve(Document document)
        {
            return _fileHelpers.IsPathRooted(document.FileStore.Path)
                ? document.FileStore.Path
                : _fileSystem.AbsolutePath(document.FileStore.Path);
        }
    }
}
