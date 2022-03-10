using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;

namespace Inprotech.Contracts.Storage
{
    public interface IStorage
    {
        Task Save(string filename, string @group, Guid id, Stream content);
        Task SaveText(string filename, string @group, Guid id, string text);
        Task<FileContent> Load(Guid id);
        Task<string> ReadAllText(Guid id);
        Task<IEnumerable<FileContent>> Load(string filename, string group);

        Task<bool> Exists(Guid id);

        Task<bool> Exists(string filename, string group);

        Task<FileMetadata> GetFileMetadata(Guid fileId);
        Task<IEnumerable<FileMetadata>> GetFileMetadata(string filename, string group);

        Task Delete(Guid fileId);
    }
}
