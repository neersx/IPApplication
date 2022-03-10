using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASENAMEREQUEST")]
    public class CaseNameRequest
    {
        [Key]
        [Column("REQUESTNO")]
        public int RequestNo { get; set; }

        [Column("CURRENTNAMENO")]
        public int? CurrentNameNo { get; set; }

        [Column("NEWNAMENO")]
        public int? NewNameNo { get; set; }

        [Column("NEWATTENTION")]
        public int? NewAttention { get; set; }

        [Column("CURRENTATTENTION")]
        public int? CurrentAttention { get; set; }
    }
}
