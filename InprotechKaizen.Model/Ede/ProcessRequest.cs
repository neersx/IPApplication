using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Configuration;

namespace InprotechKaizen.Model.Ede
{
    [Table("PROCESSREQUEST")]
    public class ProcessRequest
    {
        [Key]
        [Column("PROCESSID")]
        public int Id { get; set; }

        [Column("BATCHNO")]
        public int? BatchId { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [Column("REQUESTDATE")]
        public DateTime? RequestDate { get; set; }

        [Column("PROCESSDATE")]
        public DateTime? ProcessDate { get; set; }

        [Required]
        [MaxLength(20)]
        [Column("CONTEXT")]
        public string Context { get; set; }

        [Required]
        [MaxLength(40)]
        [Column("SQLUSER")]
        public string User { get; set; }
        
        [Required]
        [MaxLength(30)]
        [Column("REQUESTTYPE")]
        public string RequestType { get; set; }

        [MaxLength(254)]
        [Column("REQUESTDESCRIPTION")]
        public string RequestDescription { get; set; }

        [MaxLength(254)]
        [Column("STATUSMESSAGE")]
        public string StatusMessage { get; set; }

        public virtual TableCode Status { get; set; }
    }
}
