using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.StandingInstructions
{
    [Table("INSTRUCTIONLABEL")]
    public class Characteristic
    {
        [Column("FLAGNUMBER")]
        public short Id { get; set; }

        [Required]
        [MaxLength(3)]
        [Column("INSTRUCTIONTYPE")]
        public string InstructionTypeCode { get; set; }

        [MaxLength(50)]
        [Column("FLAGLITERAL")]
        public string Description { get; set; }

        [Column("FLAGLITERAL_TID")]
        public int? DescriptionTId { get; set; }

        public virtual ICollection<ValidEvent> ValidEvents { get; set; } = new Collection<ValidEvent>();

        public virtual ICollection<DataValidation.DataValidation> DataValidations { get; set; } = new Collection<DataValidation.DataValidation>();

        public virtual ICollection<ChargeRates> ChargeRates { get; set; } = new Collection<ChargeRates>();

        public virtual InstructionType InstructionType { get; set; }
    }
}