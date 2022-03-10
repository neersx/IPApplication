using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Contracts;
using Inprotech.Contracts.Storage;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Storage
{
    public interface IBuildFileSystemPaths
    {
        string GetPath(string group, Guid fileId);
    }

    public class FileSystemPathBuilder : IBuildFileSystemPaths
    {
        public string GetPath(string group, Guid fileId)
        {
            return Path.Combine(group, $"{fileId:N}.dat");
        }
    }

    public interface IStoreAndHashFiles
    {
        Task<string> StoreAndHash(string path, Stream content);
    }

    public class Md5HashingStorer : IStoreAndHashFiles
    {
        readonly IFileSystem _fileSystem;

        public Md5HashingStorer(IFileSystem fileSystem)
        {
            if (fileSystem == null) throw new ArgumentNullException("fileSystem");
            _fileSystem = fileSystem;
        }

        public async Task<string> StoreAndHash(string path, Stream content)
        {
            var hasher = MD5.Create();
            using (var outputStream = _fileSystem.OpenWrite(path))
            using (var cryptoStream = new CryptoStream(outputStream, hasher, CryptoStreamMode.Write))
            {
                await content.CopyToAsync(cryptoStream);
                cryptoStream.FlushFinalBlock();
            }

            return Convert.ToBase64String(hasher.Hash);
        }
    }

    public class FileSystemStorage : IStorage
    {
        readonly IFileMetadataRepository _fileMetadataRepository;
        readonly IFileSystem _fileSystem;
        readonly IStoreAndHashFiles _hashingStorer;
        readonly Func<DateTime> _now;
        readonly IBuildFileSystemPaths _pathBuilder;
        readonly IRepository _transactionProvider;

        public FileSystemStorage(IFileSystem fileSystem, IFileMetadataRepository fileMetadataRepository, IRepository transactionProvider,
                                 IBuildFileSystemPaths pathBuilder, Func<DateTime> now, IStoreAndHashFiles hashingStorer)
        {
            _fileSystem = fileSystem;
            _fileMetadataRepository = fileMetadataRepository;
            _transactionProvider = transactionProvider;
            _pathBuilder = pathBuilder;
            _now = now;
            _hashingStorer = hashingStorer;
        }

        public async Task Save(string filename, string group, Guid id, Stream content)
        {
            using (var transaction = _transactionProvider.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var path = _pathBuilder.GetPath(group, id);

                _fileSystem.EnsureFolderExists(path);

                var hash = await _hashingStorer.StoreAndHash(path, content);
                var size = _fileSystem.GetLength(path);

                var fm = new Contracts.Storage.FileMetadata(id, filename, group, hash, size, _now());
                _fileMetadataRepository.Add(fm);
                transaction.Complete();
            }
        }

        public Task SaveText(string filename, string group, Guid id, string text)
        {
            using (var stream = new MemoryStream(Encoding.UTF8.GetBytes(text)))
            {
                return Save(filename, group, id, stream);
            }
        }

        public Task<FileContent> Load(Guid id)
        {
            return Task.Run(() =>
                            {
                                var metadata = _fileMetadataRepository.Get(id);
                                return new FileContent(_fileSystem.OpenRead(_pathBuilder.GetPath(metadata.Group, id)), id);
                            });
        }

        public async Task<string> ReadAllText(Guid id)
        {
            var file = await Load(id);
            using (file.Content)
            using (var sr = new StreamReader(file.Content))
            {
                return await sr.ReadToEndAsync();
            }
        }

        public Task<IEnumerable<FileContent>> Load(string filename, string group)
        {
            Func<string, Guid, Stream> getStream = (g, id) =>
                                                       _fileSystem.OpenRead(_pathBuilder.GetPath(g, id));

            return Task.Run(() =>
                            {
                                var metadatas = _fileMetadataRepository.Get(filename, group);
                                return metadatas.Select(fm => new FileContent(getStream(group, fm.FileId), fm.FileId));
                            });
        }

        public Task<bool> Exists(Guid id)
        {
            return GetFileMetadata(id).ContinueWith(t => t.Result != null);
        }

        public Task<bool> Exists(string filename, string group)
        {
            return GetFileMetadata(filename, group).ContinueWith(t => t.Result.Any());
        }

        public Task<Contracts.Storage.FileMetadata> GetFileMetadata(Guid fileId)
        {
            return Task.Run(() => _fileMetadataRepository.Get(fileId));
        }

        public Task<IEnumerable<Contracts.Storage.FileMetadata>> GetFileMetadata(string filename, string group)
        {
            return Task.Run(() => _fileMetadataRepository.Get(filename, group));
        }

        public Task Delete(Guid fileId)
        {
            return Task.Run(() =>
                            {
                                var metadata = _fileMetadataRepository.Get(fileId);
                                var path = _pathBuilder.GetPath(metadata.Group, fileId);

                                using (var transaction =
                                    _transactionProvider.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
                                {
                                    _fileMetadataRepository.Delete(fileId);
                                    _fileSystem.DeleteFile(path);
                                    transaction.Complete();
                                }
                            });
        }
    }
}