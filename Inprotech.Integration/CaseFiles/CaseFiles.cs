using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Inprotech.Integration.Storage;

namespace Inprotech.Integration.CaseFiles
{
    public enum CaseFileType
    {
        MarkImage,
        MarkThumbnailImage,
        Biblio
    }

    public class CaseFiles
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int Type { get; set; }

        [Required]
        public int CaseId { get; set; }

        [Required]
        public int FileStoreId { get; set; }

        [ForeignKey("FileStoreId")]
        public virtual FileStore FileStore { get; set; }

        public DateTime? UpdatedOn { get; set; }
    }
}