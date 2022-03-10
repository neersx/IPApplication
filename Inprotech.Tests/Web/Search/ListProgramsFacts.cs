using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Search;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search
{
    public class ListProgramsFacts : FactBase
    {
        public dynamic SetData(int userProfileId)
        {
            var p1 = new ProgramBuilder {Id = "case", Name = "Case"}.Build().In(Db);
            var p2 = new ProgramBuilder {Id = "CASEENTRY", Name = "Case Entry"}.Build().In(Db);
            var p3 = new ProgramBuilder {Id = "CASEMAIN", Name = "Case Maintenance"}.Build().In(Db);
            new ProgramBuilder {Id = "name", Name = "Name Entry", ProgramGroup = "N"}.Build().In(Db);
            new ProfileProgramBuilder {ProfileId = userProfileId, Program = p1}.Build().In(Db);
            new ProfileProgramBuilder {ProfileId = userProfileId, Program = p3}.Build().In(Db);
            new ProfileProgramBuilder {ProfileId = userProfileId, Program = p2}.Build().In(Db);

            return new
            {
                p1,
                p2,
                p3
            };
        }

        [Fact]
        public void GetDefaultUserCaseProgram()
        {
            var f = new ListProgramsFixture(Db);
            var data = SetData(f.User.Profile.Id);
            new ProfileAttributeBuilder {Profile = f.User.Profile, ProfileAttributeType = ProfileAttributeType.DefaultCaseProgram, Value = data.p2.Id}.Build().In(Db);
            var result = f.Subject.GetDefaultCaseProgram();
            Assert.Equal(data.p2.Id, result);
        }

        [Fact]
        public void GetDefaultUserCaseProgramFromSiteControl()
        {
            var f = new ListProgramsFixture(Db);
            SetData(f.User.Profile.Id);
            var result = f.Subject.GetCasePrograms().ToArray();
            Assert.Equal(3, result.Length);
            Assert.True(result[2].IsDefault);
        }

        [Fact]
        public void GetDefaultUserCaseProgramFromSiteControlForExternalUser()
        {
            var f = new ListProgramsFixture(Db);
            f.SecurityContext.User.Returns(new UserBuilder(Db) {IsExternalUser = true}.Build().In(Db));
            f.SiteControlReader.Read<string>(SiteControls.CaseProgramForClientAccess).Returns(KnownCasePrograms.ClientAccess);
            var result = f.Subject.GetDefaultCaseProgram();
            Assert.Equal(KnownCasePrograms.ClientAccess, result);
        }

        [Fact]
        public void GetUserCasePrograms()
        {
            var f = new ListProgramsFixture(Db);
            var data = SetData(f.User.Profile.Id);
            new ProfileAttributeBuilder {Profile = f.User.Profile, ProfileAttributeType = ProfileAttributeType.DefaultCaseProgram, Value = data.p2.Id}.Build().In(Db);
            var result = f.Subject.GetCasePrograms().ToArray();
            Assert.Equal(3, result.Length);
            Assert.Equal(data.p1.Id, result.First().Id);
            Assert.True(result[1].IsDefault);
            Assert.Equal(data.p3.Id, result[2].Id);
        }
    }

    public class ListProgramsFixture : IFixture<ListPrograms>
    {
        public ListProgramsFixture(InMemoryDbContext db)
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            User = new UserBuilder(db) {Profile = new ProfileBuilder().Build().In(db)}.Build().In(db);
            SecurityContext.User.Returns(User);
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            Translator = Substitute.For<IStaticTranslator>();
            SiteControlReader.Read<string>(SiteControls.CaseScreenDefaultProgram).Returns("CASEMAIN");

            Subject = new ListPrograms(db, SecurityContext, SiteControlReader, PreferredCultureResolver, Translator);
        }

        public User User { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public ISiteControlReader SiteControlReader { get; set; }
        public IStaticTranslator Translator { get; set; }
        public ListPrograms Subject { get; }
    }
}