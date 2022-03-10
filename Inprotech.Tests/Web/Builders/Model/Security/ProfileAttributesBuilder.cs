using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Web.Builders.Model.Security
{
    public class ProfileAttributeBuilder : IBuilder<ProfileAttribute>
    {
        public Profile Profile { get; set; }
        public ProfileAttributeType? ProfileAttributeType { get; set; }
        public string Value { get; set; }

        public ProfileAttribute Build()
        {
            return new ProfileAttribute(
                                        Profile ?? new ProfileBuilder().Build(),
                                        ProfileAttributeType ??
                                        InprotechKaizen.Model.Security.ProfileAttributeType.MinimumImportanceLevel,
                                        Value ?? Fixture.String("Value"));
        }
    }
}