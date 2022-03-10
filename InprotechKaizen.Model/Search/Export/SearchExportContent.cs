using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Search.Export
{
    [Table("REPORTCONTENTRESULT")]
    public class ReportContentResult
    {
        [Key]
        [Column("ID")]
        public int Id { get; set; }

        [Column("CONTENT")]
        public byte[] Content { get; set; }

        [MaxLength(100)]
        [Column("CONTENTTYPE")]
        public string ContentType { get; set; }

        [MaxLength(508)]
        [Column("FILENAME")]
        public string FileName { get; set; }

        [Column("CONNECTIONID")]
        public string ConnectionId { get; set; }

        [Column("PROCESSID")]
        public int? ProcessId { get; set; }

        [Column("ERROR")]
        public string Error { get; set; }

        [Column("STARTED")]
        public DateTime? Started { get; set; }

        [Column("FINISHED")]
        public DateTime? Finished { get; set; }

        [Column("STATUS")]
        public int? Status { get; set; }

        [Column("IDENTITYID")]
        public int IdentityId { get; set; }

        [ForeignKey("ProcessId")]
        public virtual BackgroundProcess.BackgroundProcess BackgroundProcess { get; set; }
    }
}
