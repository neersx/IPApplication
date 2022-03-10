using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.Storage
{
    [Table("FileMetadata")]
    public class FileMetadata
    {
        [Obsolete("For persistence only.")]
        public FileMetadata()
        {
            
        }

        public FileMetadata(Contracts.Storage.FileMetadata metadata)
        {
            FileId = metadata.FileId;
            Filename = metadata.Filename;
            FileGroup = metadata.Group;
            ContentHash = metadata.ContentHash;
            FileSize = metadata.Size;
            SavedOn = metadata.SavedOn;
        }

        public long Id { get; protected set; }

        public Guid FileId { get; set; }

        public string Filename { get; set; }

        public string FileGroup { get; set; }

        public string ContentHash { get; set; }

        public long FileSize { get; set; }

        public string MimeType { get; set; }

        public DateTime SavedOn { get; set; }
    }
}
