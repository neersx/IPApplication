using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Web.Builders.Model.Security
{
    public class ProfileBuilder : IBuilder<Profile>
    {
        public int? ProfileId { get; set; }
        public string ProfileName { get; set; }

        public Profile Build()
        {
            return new Profile(
                               ProfileId ?? Fixture.Integer(),
                               ProfileName ?? Fixture.String());
        }
    }
}