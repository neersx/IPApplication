using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Web.Builders.Model.Security
{
    public class ProfileProgramBuilder : IBuilder<ProfileProgram>
    {
        public int? ProfileId { get; set; }

        public Program Program { get; set; }

        public ProfileProgram Build()
        {
            return new ProfileProgram(
                               ProfileId ?? Fixture.Integer(),
                               Program ?? new ProgramBuilder().Build());
        }
    }
}