using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    internal class NameTypeBuilder : Builder
    {
        public NameTypeBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public NameType Create()
        {
            return InsertWithNewId(new NameType
                                   {
                                       NameTypeCode = Fixture.UriSafeString(3),
                                       Name = Fixture.AlphaNumericString(10)
                                   });
        }
    }
}