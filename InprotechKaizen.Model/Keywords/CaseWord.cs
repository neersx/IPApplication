using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Keywords
{
    [Table("CASEWORDS")]
    public class CaseWord
    {
        [Column("KEYWORDNO", Order = 0)]
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int KeywordNo { get; set; }

        [Column("CASEID", Order = 1)]
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int CaseId { get; set; }
    }
}
