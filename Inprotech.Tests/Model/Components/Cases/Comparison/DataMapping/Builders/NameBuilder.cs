using Inprotech.Tests.Web.Builders;
using ComparisonModel = InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders
{
    public class NameBuilder : IBuilder<ComparisonModel.Name>
    {
        public string FreeFormatName { get; set; }

        public string CountryCode { get; set; }

        public ComparisonModel.Name Build()
        {
            return new ComparisonModel.Name
            {
                FreeFormatName = FreeFormatName ?? Fixture.String(),
                CountryCode = CountryCode ?? Fixture.String()
            };
        }
    }
}