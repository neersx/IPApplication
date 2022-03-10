using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.BackgroundProcess
{
    [Table("BACKGROUNDPROCESS")]
    public class BackgroundProcess
    {
        [Key]
        [Column("PROCESSID")]
        public int Id { get; set; }

        [Column("IDENTITYID")]
        public int IdentityId { get; set; }

        [MaxLength(30)]
        [Column("PROCESSTYPE")]
        public string ProcessType { get; set; }

        [Column("STATUS")]
        public int Status { get; set; }

        [Column("STATUSDATE")]
        public DateTime StatusDate { get; set; }

        [MaxLength(1000)]
        [Column("STATUSINFO")]
        public string StatusInfo { get; set; }

        [MaxLength(30)]
        [Column("PROCESSSUBTYPE")]
        public string ProcessSubType { get; set; }
    }
}