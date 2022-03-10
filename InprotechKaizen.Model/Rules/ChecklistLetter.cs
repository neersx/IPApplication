using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Rules
{
    [Table("CHECKLISTLETTER")]
    public class ChecklistLetter
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("CRITERIANO")]
        public int CriteriaId { get; set; }
        [Column("LETTERNO")]
        public short LetterNo { get; set; }
        [Column("QUESTIONNO")]
        public short? QuestionId { get; set; }
        [Column("REQUIREDANSWER")]
        public decimal? RequiredAnswer { get; set; }
    }

    public enum KnownRequiredAnswer
    {
        None,
        Yes,
        No,
        YesOrNo
    }
}
