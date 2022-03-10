using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    class NameRelationBuilder : Builder
    {
        public NameRelationBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public NameRelation Create()
        {
            return InsertWithNewId(new NameRelation {RelationDescription = "Relationship_" + Fixture.String(5)} );
        }
    }
}