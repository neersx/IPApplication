using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Names
{
    public class NameRelationBuilder : IBuilder<NameRelation>
    {
        public NameRelation Build()
        {
            return new NameRelation(
                                    Fixture.String("NameRelation"),
                                    Fixture.String("RelationDesc"),
                                    Fixture.String("ReverseDesc"),
                                    Fixture.Decimal(),
                                    null,
                                    new byte());
        }
    }
}