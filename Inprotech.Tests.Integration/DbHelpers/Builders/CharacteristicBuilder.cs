using System.Linq;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    class CharacteristicBuilder : Builder
    {
        public CharacteristicBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public Characteristic Create(string instructionTypeCode, string description = null)
        {            
            var newId = (short)(DbContext.Set<Characteristic>().Max(_ => _.Id) + 1);

            return Insert(new Characteristic
            {
                Id = newId,
                InstructionTypeCode = instructionTypeCode,
                Description = description ?? Fixture.String(5)
            });
        }
    }
}
