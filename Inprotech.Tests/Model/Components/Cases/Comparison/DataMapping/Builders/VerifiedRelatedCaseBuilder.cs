using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders
{
    public class VerifiedRelatedCaseBuilder : IBuilder<VerifiedRelatedCase>
    {
        public string CountryCode { get; set; }
        public string Description { get; set; }
        public string RelationshipCode { get; set; }

        public VerifiedRelatedCase Build()
        {
            return new VerifiedRelatedCase
            {
                CountryCode = CountryCode ?? Fixture.String(),
                Description = Description ?? Fixture.String(),
                RelationshipCode = RelationshipCode ?? Fixture.String()
            };
        }
    }
}