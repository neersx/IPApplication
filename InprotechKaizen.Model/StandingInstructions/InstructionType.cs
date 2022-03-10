using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.StandingInstructions
{
    [Table("INSTRUCTIONTYPE")]
    public class InstructionType
    {
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("ID")]
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(3)]
        [Column("INSTRUCTIONTYPE")]
        public string Code { get; set; }

        [Column("NAMETYPE")]
        public NameType NameType { get; set; }

        [MaxLength(50)]
        [Column("INSTRTYPEDESC")]
        public string Description { get; set; }

        [Column("INSTRTYPEDESC_TID")]
        public int? DescriptionTId { get; set; }

        [MaxLength(3)]
        [Column("RESTRICTEDBYTYPE")]
        public string RestrictedByTypeCode { get; set; }

        public virtual NameType RestrictedByType { get; set; }

        public virtual ICollection<Instruction> Instructions { get; set; } = new Collection<Instruction>();

        public virtual ICollection<Characteristic> Characteristics { get; set; } = new Collection<Characteristic>();
    }
}