using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class InstructionTypeBuilder : IBuilder<InstructionType>
    {
        public string Code { get; set; }

        public string Description { get; set; }
        
        public InstructionType Build()
        {
            return new InstructionType
            {
                Code = Code,
                Description = Description ?? Fixture.String()
            };
        }
    }

    public class FilteredUserInstructionTypeBuilder : IBuilder<FilteredUserInstructionType>
    {
        public string InstructionTypeCode { get; set; }

        public string InstructionDescription { get; set; }

        public FilteredUserInstructionType Build()
        {
            return new FilteredUserInstructionType
            {
                InstructionDescription = InstructionDescription ?? Fixture.String(),
                InstructionType = InstructionTypeCode ?? Fixture.String()
            };
        }
    }
}