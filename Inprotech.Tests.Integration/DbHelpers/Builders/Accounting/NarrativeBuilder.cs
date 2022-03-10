using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders.Accounting
{
    internal class NarrativeBuilder : Builder
    {
        public NarrativeBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public Narrative Create(string code = null)
        {
            return InsertWithNewId(new Narrative
            {
                NarrativeCode = code ?? Fixture.AlphaNumericString(6),
                NarrativeTitle = code + " Testing Narrative",
                NarrativeText = code + " is testing this Narrative"
            });
        }
    }
}