using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede
{
    [Table("EDECASEMATCH")]
    public class EdeCaseMatch
    {
        [Key]
        [Column("DRAFTCASEID")]
        public int DraftCaseId { get; set; }

        [Column("LIVECASEID")]
        public int? LiveCaseId { get; set; } 

        [Column("MATCHLEVEL")]
        public int? MatchLevel { get; set; }
    }
}