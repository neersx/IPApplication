using System.Collections.Generic;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Configuration.Rules.StandingInstructions
{
    public class DeltaInstructionTypeDetails
    {
        public int Id { get; set; }
        public Delta<DeltaInstruction> Instructions { get; set; }
        public Delta<DeltaCharacteristic> Characteristics { get; set; }

        public DeltaInstructionTypeDetails()
        {
            Instructions = new Delta<DeltaInstruction>();
            Characteristics= new Delta<DeltaCharacteristic>();
        }
    }

    public class DeltaInstruction
    {
        public string Id { get; set; }
        public string Description { get; set; }
        public ICollection<DeltaCharacteristic> Characteristics { get; set; }
        public string CorrelationId { get; set; }

        public DeltaInstruction()
        {
            Characteristics = new List<DeltaCharacteristic>();
        }
    }

    public class DeltaCharacteristic
    {
        public string Id { get; set; }
        public string Description { get; set; }
        public bool Selected { get; set; }
        public string CorrelationId { get; set; }
    }
}
