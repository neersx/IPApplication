using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class CountryGroupBuilder : IBuilder<CountryGroup>
    {
        public string Id { get; set; }
        public string CountryCode { get; set; }
        public Country GroupMember { get; set; }

        public CountryGroup Build()
        {
            var memberId = GroupMember == null ? CountryCode ?? Fixture.String("Country") : GroupMember.Id;
            return new CountryGroup(Id ?? Fixture.String("Id"), memberId) {GroupMember = GroupMember};
        }
    }
}