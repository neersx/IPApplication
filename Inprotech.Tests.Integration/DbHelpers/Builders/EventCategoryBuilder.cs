using System;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    internal class EventCategoryBuilder : Builder
    {
        public EventCategoryBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public EventCategory Create(string name = null,
                                    string description = null)
        {
            var image = InsertWithNewId(new Image {ImageData = Convert.FromBase64String(@"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")});
            return InsertWithNewId(new EventCategory
                                   {
                                       Name = Fixture.Prefix(name ?? Fixture.String(3)),
                                       Description = Fixture.Prefix(name ?? Fixture.String(3)),
                                       ImageId = image.Id
                                   });
        }
    }
}