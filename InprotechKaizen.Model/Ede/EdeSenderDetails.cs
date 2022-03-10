using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede
{
    [Table("EDESENDERDETAILS")]
    public class EdeSenderDetails
    {
        [Key]
        [Column("ROWID")]
        public int RowId { get; set; }

        [MaxLength(50)]
        [Column("SENDERREQUESTTYPE")]
        public string SenderRequestType { get; set; }

        [Required]
        [MaxLength(254)]
        [Column("SENDERREQUESTIDENTIFIER")]
        public string SenderRequestIdentifier { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("SENDER")]
        public string Sender { get; set; }

        [Column("SENDERNAMENO")]
        public int? SenderNameNo { get; set; }

        [MaxLength(254)]
        [Column("SENDERFILENAME")]
        public string SenderFileName { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastModified { get; set; }

        public virtual EdeTransactionHeader TransactionHeader { get; set; }
    }
}
