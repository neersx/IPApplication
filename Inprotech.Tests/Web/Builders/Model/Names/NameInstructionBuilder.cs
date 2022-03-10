using System;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Names
{
    public class NameInstructionBuilder : IBuilder<NameInstruction>
    {
        public int? Id { get; set; }

        public int? Sequence { get; set; }

        public int? RestrictedToName { get; set; }

        public short? InstructionId { get; set; }

        public int? CaseId { get; set; }

        public string CountryCode { get; set; }

        public string PropertyType { get; set; }

        public short? Period1Amt { get; set; }

        public string Period1Type { get; set; }

        public short? Period2Amt { get; set; }

        public string Period2Type { get; set; }

        public short? Period3Amt { get; set; }

        public string Period3Type { get; set; }

        public string Adjustment { get; set; }

        public byte? AdjustDay { get; set; }

        public byte? AdjustStartMonth { get; set; }

        public byte? AdjustDayOfWeek { get; set; }

        public DateTime? AdjustToDate { get; set; }

        public string StandingInstructionText { get; set; }

        public NameInstruction Build()
        {
            return new NameInstruction
            {
                Id = Id ?? Fixture.Integer(),
                Sequence = Sequence ?? Fixture.Short(),
                RestrictedToName = RestrictedToName ?? Fixture.Integer(),
                InstructionId = InstructionId ?? Fixture.Short(),
                CaseId = CaseId ?? Fixture.Integer(),
                CountryCode = CountryCode ?? Fixture.String(),
                PropertyType = PropertyType ?? Fixture.String(),
                Period1Amt = Period1Amt ?? Fixture.Short(),
                Period1Type = Period1Type ?? Fixture.String(),
                Period2Amt = Period2Amt ?? Fixture.Short(),
                Period2Type = Period2Type ?? Fixture.String(),
                Period3Amt = Period3Amt ?? Fixture.Short(),
                Period3Type = Period3Type ?? Fixture.String(),
                Adjustment = Adjustment ?? Fixture.String(),
                AdjustDay = AdjustDay ?? (byte)(Fixture.Boolean() ? 1 : 0),
                AdjustStartMonth = AdjustStartMonth ?? (byte)(Fixture.Boolean() ? 1 : 0),
                AdjustDayOfWeek = AdjustDayOfWeek ?? (byte)(Fixture.Boolean() ? 1 : 0),
                AdjustToDate = AdjustToDate ?? Fixture.Today(),
                StandingInstructionText = StandingInstructionText ?? Fixture.String()
            };
        }
    }
}