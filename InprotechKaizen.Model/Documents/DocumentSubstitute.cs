using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Documents
{
    [Table("LETTERSUBSTITUTE")]
    public class DocumentSubstitute
    {
        [Key]
        [Column("LETTERNO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short Id { get; set; }

        [Key]
        [Column("SEQUENCE", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short Sequence { get; set; }

        [Column("ALTERNATELETTER")]
        public short? AlternateDocument { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [Column("INSTRUCTIONCODE")]
        public short? InstructionCode { get; set; }

        [Column("NAMENO")]
        public int? NameId { get; set; }

        [Column("CATEGORY")]
        public int? CategoryId { get; set; }

        [Column("LANGUAGE")]
        public int? LanguageId { get; set; }

        [MaxLength(3)]
        [Column("CASECOUNTRYCODE")]
        public string CaseCountryId { get; set; }
    }
}