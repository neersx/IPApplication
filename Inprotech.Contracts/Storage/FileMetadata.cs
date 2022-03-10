using System;

namespace Inprotech.Contracts.Storage
{
    public class FileMetadata
    {
        public readonly Guid FileId;
        public readonly string Filename;
        public readonly string Group;
        public readonly string ContentHash;
        public readonly long Size;
        public readonly DateTime SavedOn;

        public FileMetadata(Guid fileId, string filename, string group, string contentHash, long size, DateTime savedOn)
        {
            if(fileId == Guid.Empty) throw new ArgumentNullException("fileId");
            if(String.IsNullOrEmpty(filename)) throw new ArgumentNullException("filename");
            if(String.IsNullOrEmpty(group)) throw new ArgumentNullException("group");
            if(String.IsNullOrEmpty(contentHash)) throw new ArgumentNullException("contentHash");
            if(size == 0) throw new ArgumentOutOfRangeException("size");

            FileId = fileId;
            Filename = filename;
            Group = group;
            ContentHash = contentHash;
            Size = size;
            SavedOn = savedOn;
        }
    }
}