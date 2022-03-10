using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.StandingInstructions
{
    [Table("INSTRUCTIONS")]
    public class Instruction
    {
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("INSTRUCTIONCODE", Order = 1)]
        public short Id { get; set; }

        [MaxLength(3)]
        [Column("INSTRUCTIONTYPE")]
        public string InstructionTypeCode { get; set; }

        [MaxLength(50)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }

        public virtual InstructionType InstructionType { get; set; }

        public virtual ICollection<SelectedCharacteristic> Characteristics { get; set; } = new Collection<SelectedCharacteristic>();

        public virtual ICollection<CaseInstruction> CaseInstructions { get; set; } = new Collection<CaseInstruction>();

        public virtual ICollection<NameInstruction> NameInstructions { get; set; } = new Collection<NameInstruction>();
    }
}
