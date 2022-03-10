using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    public class InstructionTypeBuilder : Builder
    {
        public string InstructionTypeId { get; set; }
        public InstructionTypeBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public InstructionType Create(string description = null)
        {
            var nameTypeBuilder = new NameTypeBuilder(DbContext);

            return Insert(new InstructionType
                          {
                              Code = InstructionTypeId ?? Fixture.UriSafeString(3),
                              Description = description ?? Fixture.String(5),
                              NameType = nameTypeBuilder.Create()
                          });
        }
    }
}