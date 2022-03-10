using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Web.Builders.Model.ValidCombinations
{
    public class ValidRelationshipBuilder : IBuilder<ValidRelationship>
    {
        public CaseRelation Relation { get; set; }
        public Country Country { get; set; }
        public PropertyType PropertyType { get; set; }

        public ValidRelationship Build()
        {
            return new ValidRelationship(
                                         Country ?? new CountryBuilder().Build(),
                                         PropertyType ?? new PropertyTypeBuilder().Build(),
                                         Relation ?? new CaseRelationBuilder().Build());
        }
    }
}