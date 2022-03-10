using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    class DocumentBuilder : Builder
    {
        public DocumentBuilder(IDbContext dbContext) : base(dbContext)
        {

        }

        public Document Create(string name)
        {
            return InsertWithNewId(new Document(Fixture.Prefix(name), Fixture.String(10)));
        }
    }
}
