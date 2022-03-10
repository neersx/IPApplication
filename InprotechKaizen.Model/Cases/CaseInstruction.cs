using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASEINSTRUCTIONS")]
    public class CaseInstruction
    {
        [Obsolete("For persistence only.")]
        public CaseInstruction()
        {
        }

        public CaseInstruction(int caseId, string instructionType, short instructionId)
        {
            Id = caseId;
            InstructionType = instructionType;
            InstructionId = instructionId;
        }

        [Column("CASEID", Order = 1)]
        [Key]
        public int Id { get; set; }

        [Column("INSTRUCTIONTYPE", Order = 2)]
        [Key]
        [MaxLength(3)]
        public string InstructionType { get; set; }

        [Column("INSTRUCTIONCODE")]
        public short InstructionId { get; set; }
    }
}
