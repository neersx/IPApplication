using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.StandingInstructions
{
    [Table("INSTRUCTIONFLAG")]
    public class SelectedCharacteristic
    {
        [Column("INSTRUCTIONCODE")]
        public short InstructionId { get; set; }

        [Column("FLAGNUMBER")]
        public short CharacteristicId { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("INSTRUCTIONFLAG")]
        public decimal? InstructionFlag { get; set; }

        public virtual Instruction Instruction { get; set; }
    }
}