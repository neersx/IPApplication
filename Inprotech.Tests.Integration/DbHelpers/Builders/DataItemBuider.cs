using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    class DataItemBuider : Builder
    {
        public DataItemBuider(IDbContext dbContext) : base(dbContext)
        {

        }

        public DocItem Create(short itemType ,string sql, string name = null, string description = null)
        {
            return InsertWithNewId(new DocItem
            {
                Name = name ?? Fixture.String(40),
                Description = description ?? Fixture.String(254),
                ItemType = itemType,
                Sql = sql
            });
        }
    }
}
