using System;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class OfficialNumberBuilder : IBuilder<OfficialNumber>
    {
        public NumberType NumberType { get; set; }
        public int? CaseId { get; set; }
        public Case Case { get; set; }
        public string OfficialNo { get; set; }
        public decimal? IsCurrent { get; set; }
        public DateTime? DateEntered { get; set; }

        public OfficialNumber Build()
        {
            var @case = Case ?? new CaseBuilder()
                                .Build()
                                .WithKnownId(CaseId ?? Fixture.Integer());

            return new OfficialNumber(
                                      NumberType ?? new NumberTypeBuilder().Build(),
                                      @case,
                                      OfficialNo ?? Fixture.String("Number"))
            {
                IsCurrent = IsCurrent ?? 1,
                DateEntered = DateEntered
            };
        }
    }

    public static class OfficialNumberBuilderEx
    {
        public static OfficialNumberBuilder AsCurrent(this OfficialNumberBuilder builder)
        {
            builder.IsCurrent = 1;
            return builder;
        }

        public static OfficialNumberBuilder Of(this OfficialNumberBuilder builder, NumberType numberType)
        {
            builder.NumberType = numberType;
            return builder;
        }

        public static OfficialNumberBuilder For(this OfficialNumberBuilder builder, Case @case)
        {
            if (@case != null) builder.CaseId = @case.Id;
            return builder;
        }
    }
}