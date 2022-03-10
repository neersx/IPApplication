using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Cases
{
    [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "InstructionDefinition")]
    [Table("INSTRUCTIONDEFINITION")]
    public class InstructionDefinition
    {
        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        [Obsolete("For persistence only.")]
        public InstructionDefinition()
        {
            
        }

        public InstructionDefinition( string instructionName, Boolean useMaxCycle, int availabilityFlag)
        {
            InstructionName = instructionName;
            UseMaxCycle = useMaxCycle;
            AvailabilityFlag = availabilityFlag;
        }
        
        [Column("DEFINITIONID")]
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; internal set; }

        [Column("INSTRUCTIONNAME")]
        public string InstructionName { get; set; }

        [Column("AVAILABILITYFLAGS")]
        public int AvailabilityFlag { get; set; }

        [Column("EXPLANATION")]
        public string Explanation { get; set; }

        [Column("DUEEVENTNO")]
        public int? DueEventNo { get; set; }

        [Column("USEMAXCYCLE")]
        public bool UseMaxCycle { get; set; }
    }
}
