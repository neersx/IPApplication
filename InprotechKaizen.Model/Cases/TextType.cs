using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("TEXTTYPE")]
    public class TextType
    {
        public TextType()
        {
            
        }

        public TextType(string description) : this()
        {
            TextDescription = description;
        }

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("TEXTTYPE")]
        [MaxLength(2)]
        public string Id { get; set; }

        [MaxLength(50)]
        [Column("TEXTDESCRIPTION")]
        public string TextDescription { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("USEDBYFLAG")]
        public short? UsedByFlag { get; set; }

        [Column("TEXTDESCRIPTION_TID")]
        public int? TextDescriptionTId { get; set; }

        public bool UsedByCase => !UsedByFlag.HasValue || UsedByFlag == (short)KnownTextTypeUsedBy.Case;

        public bool UsedByEmployee => Convert.ToBoolean(UsedByFlag & (short)KnownTextTypeUsedBy.Employee);

        public bool UsedByIndividual => Convert.ToBoolean(UsedByFlag & (short)KnownTextTypeUsedBy.Individual);

        public bool UsedByOrganisation => Convert.ToBoolean(UsedByFlag & (short)KnownTextTypeUsedBy.Organisation);
    }
}