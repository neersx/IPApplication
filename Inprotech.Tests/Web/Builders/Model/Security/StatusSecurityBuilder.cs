using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Web.Builders.Model.Security
{
    public class StatusSecurityBuilder : IBuilder<StatusSecurity>
    {
        public short? AccessLevel;
        public short? StatusId;
        public string UserName;

        public StatusSecurity Build()
        {
            return new StatusSecurity(
                                      UserName ?? Fixture.String(),
                                      StatusId ?? Fixture.Short(),
                                      AccessLevel ?? 1);
        }
    }
}