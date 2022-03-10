using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.ContactActivities
{
    [Table("DOCUMENTREQUEST")]
    public class DocumentRequest
    {
        [Key]
        [Column("REQUESTID")]
        public int RequestId { get; set; }

        [Column("RECIPIENT")]
        public int Recipient { get; set; }
    }
}
