using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Storage
{
    public interface IFileMetadataRepository
    {
        void Add(Inprotech.Contracts.Storage.FileMetadata metadata);
        IEnumerable<Inprotech.Contracts.Storage.FileMetadata> Get(string filename, string fileGroup);
        Inprotech.Contracts.Storage.FileMetadata Get(Guid fileId);
        IEnumerable<Inprotech.Contracts.Storage.FileMetadata> Get(string fileGroup); 
        void Delete(Guid fileId);
    }

    public class FileMetadataRepository : IFileMetadataRepository
    {
        private readonly IRepository _repository;

        public FileMetadataRepository(IRepository repository)
        {
            if (repository == null) throw new ArgumentNullException("repository");
            _repository = repository;
        }

        public void Add(Inprotech.Contracts.Storage.FileMetadata metadata)
        {
            using (var transaction = _repository.BeginTransaction())
            {
                var fm = new FileMetadata(metadata);
                _repository.Set<FileMetadata>().Add(fm);
                _repository.SaveChanges();
                transaction.Complete();
            }
        }

        public IEnumerable<Inprotech.Contracts.Storage.FileMetadata> Get(string filename, string fileGroup)
        {
            return _repository.Set<FileMetadata>()
                .Where(fm => fm.Filename.Equals(filename, StringComparison.OrdinalIgnoreCase) &&
                        fm.FileGroup.Equals(fileGroup, StringComparison.OrdinalIgnoreCase))
                .ToArray()
                .Select(fm => new Inprotech.Contracts.Storage.FileMetadata(fm.FileId, fm.Filename, fm.FileGroup,
                            fm.ContentHash, fm.FileSize, fm.SavedOn));
        }
        public IEnumerable<Inprotech.Contracts.Storage.FileMetadata> Get(string fileGroup)
        {
            return _repository.Set<FileMetadata>()
                .Where(fm => fm.FileGroup.Equals(fileGroup, StringComparison.OrdinalIgnoreCase))
                .ToArray()
                .Select(fm => new Inprotech.Contracts.Storage.FileMetadata(fm.FileId, fm.Filename, fm.FileGroup,
                            fm.ContentHash, fm.FileSize, fm.SavedOn));
        }
        
        public Inprotech.Contracts.Storage.FileMetadata Get(Guid fileId)
        {
            return _repository.Set<FileMetadata>()
                .Where(fm => fm.FileId == fileId)
                .ToArray()
                .Select(fm => new Inprotech.Contracts.Storage.FileMetadata(fm.FileId, fm.Filename, fm.FileGroup,
                            fm.ContentHash, fm.FileSize, fm.SavedOn))
                .FirstOrDefault();
        }

        public void Delete(Guid fileId)
        {
            using (var transaction = _repository.BeginTransaction())
            {
                var set = _repository.Set<FileMetadata>();

                var fileMetadata = set.FirstOrDefault(fm => fm.FileId == fileId);
                if (fileMetadata != null)
                {
                    set.Remove(fileMetadata);
                    _repository.SaveChanges();
                }

                transaction.Complete();
            }
        }
    }
}
