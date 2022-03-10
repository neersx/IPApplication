using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Search;
using Inprotech.Web.Security.Access;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Security.Access
{

    public class AllowableProgramsResolverFacts : FactBase
    {
        public class AllowableProgramsResolverFixture : IFixture<AllowableProgramsResolver>
        {
            readonly ISecurityContext _securityContext;
            public AllowableProgramsResolverFixture(InMemoryDbContext db)
            {
                _securityContext = Substitute.For<ISecurityContext>();
                ListCasePrograms = Substitute.For<IListPrograms>();
                Subject = new AllowableProgramsResolver(_securityContext, db, ListCasePrograms);
            }

            public AllowableProgramsResolverFixture WithUser(User user)
            {
                _securityContext.User.Returns(user);
                return this;
            }

            public AllowableProgramsResolverFixture WithDefaultProgram(string defaultProgram)
            {
                ListCasePrograms.GetDefaultCaseProgram().Returns(defaultProgram);
                return this;
            }

            public AllowableProgramsResolver Subject { get; }

            public IListPrograms ListCasePrograms { get; set; }
        }
        
        [Fact]
        public async Task ReturnsRecordsWithProfileIdOrDefaultProgramId()
        {
            var user = CreateUser(Fixture.String(), Fixture.String(), true);
            user.Profile = new Profile(Fixture.Integer(), Fixture.String());
            var programs = new[]
            {
                new ProfileProgram() { ProfileId = Fixture.Integer(), ProgramId = Fixture.String()},
                new ProfileProgram() { ProfileId = Fixture.Integer(), ProgramId = Fixture.String()},
                new ProfileProgram() { ProfileId = user.Profile.Id, ProgramId = Fixture.String()}
            }.In(Db);
            var subject = new AllowableProgramsResolverFixture(Db).WithDefaultProgram(programs[0].ProgramId).WithUser(user).Subject;
            var resolvedProgramIds = (await subject.Resolve()).ToArray();

            Assert.Equal(2, resolvedProgramIds.Length);
            Assert.Equal(programs[0].ProgramId, resolvedProgramIds[0]);
            Assert.Equal(programs[2].ProgramId, resolvedProgramIds[1]);
        }

        [Fact]
        public async Task ReturnsDefaultProgramIfUserProfileNull()
        {
            var defaultProgram = "CASENTRY";
            var user = CreateUser(Fixture.String(), Fixture.String(), true);
            var fixture = new AllowableProgramsResolverFixture(Db).WithUser(user);
            fixture.ListCasePrograms.GetDefaultCaseProgram().Returns(defaultProgram);
            var allowed = (await fixture.Subject.Resolve()).ToArray();
            Assert.Equal(1, allowed.Length);
            Assert.Equal(defaultProgram, allowed[0]);
        }
    }
}