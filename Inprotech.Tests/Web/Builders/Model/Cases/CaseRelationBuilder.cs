using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class CaseRelationBuilder : IBuilder<CaseRelation>
    {
        public string RelationshipCode { get; set; }
        public string RelationshipDescription { get; set; }
        public int? FromEventId { get; set; }

        public CaseRelation Build()
        {
            return new CaseRelation(
                                    RelationshipCode ?? Fixture.String("RES"),
                                    RelationshipDescription ?? Fixture.String("Name"),
                                    FromEventId ?? Fixture.Integer());
        }
    }
}