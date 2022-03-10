using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    class CaseRelationBuilder : Builder
    {
        public CaseRelationBuilder(IDbContext dbContext) : base(dbContext)
        {

        }

        public CaseRelation Create(string description)
        {
            return InsertWithNewId(new CaseRelation
                                       {
                                           Description = description
                                       });
        }
    }
}
