using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    public class AssociatedNameBuilder : Builder
    {
        public AssociatedNameBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public AssociatedName Create(Name name, Name existingAssName, string relationshipType)
        {
            var associatedName = existingAssName ?? InsertWithNewId(new Name
            {
                FirstName = "jim",
                LastName = "ass",
                MiddleName = "e2e",
                NameCode = Fixture.String(20),
                UsedAs = KnownNameTypeAllowedFlags.Individual,
                SearchKey1 = "ASS",
                Remarks = RandomString.Next(30)
            });

            return Insert(new AssociatedName(name, associatedName, relationshipType, 0));
        } 
    }
}
