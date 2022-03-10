using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Cases
{
    
    [Table("INSTRUCTIONRESPONSE")]
    public class InstructionResponse
    {
        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        [Obsolete("For persistence only.")]
        public InstructionResponse()
        {

        }
        
        public InstructionResponse(int definitionId, short sequenceNo,  string label, int? fireEventNo)
        {
            DefinitionId= definitionId;
            Label = label;
            SequenceNo = sequenceNo;
            FireEventNo = fireEventNo;
        }

        [Key]
        [Column("DEFINITIONID", Order = 1)]
        public int DefinitionId { get; set; }

        [Key]
        [Column("SEQUENCENO", Order = 2)]
        public short SequenceNo { get; set; }

        [Column("LABEL")]
        public string Label { get; set; }

        [Column("LABEL_TID")]
        public int? LabelTId { get; set; }

        [Column("FIREEVENTNO")]
        public int? FireEventNo { get; set; }

        [Column("EXPLANATION")]
        public string Explanation { get; set; } 

        [Column("EXPLANATION_TID")]
        public int? ExplanationTId { get; set; }

        [Column("DISPLAYEVENTNO")]
        public int? DisplayEventNo { get; set; }

        [Column("HIDEEVENTNO")]
        public int? HideEventNo { get; set; }

        [Column("NOTESPROMPT")]
        public string NotesPrompt { get; set; }

        [Column("NOTESPROMPT_TID")]
        public int? NotesPromptTId { get; set; }
    }
}
