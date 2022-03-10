using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class ProgramPicklistControllerFacts : FactBase
    {
        readonly ISiteControlReader _siteControl = Substitute.For<ISiteControlReader>();
        readonly IPreferredCultureResolver _culture = Substitute.For<IPreferredCultureResolver>();
        [Theory]
        [InlineData("pro")]
        [InlineData("gra")]
        [InlineData("mde")]
        [InlineData("script")]
        [InlineData("nam")]
        public async Task ShouldReturnNameContains(string query)
        {
            new Program("programname", "programdescription").In(Db);
            new Program("zzzzzzzzzzz", "yyyyyyyyyyyy").In(Db);

            var pagedResults = await new ProgramPicklistController(Db, _culture, _siteControl).Search(null, query);
            var r = pagedResults.Data.ToArray();

            Assert.Single(r);
            Assert.Equal("programname", r.First().Key);
            Assert.Equal("programdescription", r.First().Value);
        }

        [Fact]
        public async Task ShouldReturnsProgramsStartsWithFollowedByContains()
        {
            new Program("programname1", "programDescription1").In(Db);
            new Program("nameOfProgram2", "programDescription2").In(Db);
            new Program("failProgram3", "programDescription3").In(Db);
            new Program("failProgram4", "programDescription4").In(Db);

            var pagedResults = await new ProgramPicklistController(Db,  _culture, _siteControl).Search(null, "name");
            var r = pagedResults.Data.ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal("nameOfProgram2", r.First().Key);
            Assert.Equal("programDescription2", r.First().Value);

            Assert.Equal("programname1", r.Last().Key);
            Assert.Equal("programDescription1", r.Last().Value);
        }

        [Fact]
        public async Task ShouldReturnProgramWithGroup()
        {
            var projectGroup1 = Fixture.String();
            var projectGroup2 = Fixture.String();
            new Program("programname1", "programDescription1", projectGroup1).In(Db);
            new Program("programname2", "programDescription2").In(Db);
            new Program("programname3", "programDescription3", projectGroup1).In(Db);
            new Program("programname4", "programDescription4", projectGroup2).In(Db);

            var pagedResults = await new ProgramPicklistController(Db,  _culture, _siteControl).Search(null, programGroup: projectGroup1);
            var r = pagedResults.Data.ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal("programname1", r.First().Key);
            Assert.Equal("programDescription1", r.First().Value);

            Assert.Equal("programname3", r.Last().Key);
            Assert.Equal("programDescription3", r.Last().Value);
        }
        
        [Fact]
        public async Task ShouldReturnProgramWithParentInGroup()
        {
            var projectGroup1 = Fixture.String();
            var projectGroup2 = Fixture.String();
            var parent1 = new Program("programname1", "programDescription1", projectGroup1).In(Db);
            new Program("programname2", "programDescription2").In(Db);
            new Program("programname3", "programDescription3", parentProgram: parent1).In(Db);
            new Program("programname4", "programDescription4", projectGroup2).In(Db);

            var pagedResults = await new ProgramPicklistController(Db,  _culture, _siteControl).Search(null, programGroup: projectGroup1);
            var r = pagedResults.Data.ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal("programname1", r.First().Key);
            Assert.Equal("programDescription1", r.First().Value);

            Assert.Equal("programname3", r.Last().Key);
            Assert.Equal("programDescription3", r.Last().Value);
        }

        [Fact]
        public async Task ShouldNotReturnCrmScreenControlProgram()
        {
            new Program("programname1", "programDescription1").In(Db);
            new Program("programname2", "programDescription2").In(Db);
            new Program("programname3", "programDescription3").In(Db);
            _siteControl.Read<string>(Arg.Any<string>()).Returns("programname2");

            var pagedResults = await new ProgramPicklistController(Db,  _culture, _siteControl).Search(null);
            var r = pagedResults.Data.ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal("programname1", r.First().Key);
            Assert.Equal("programDescription1", r.First().Value);

            Assert.Equal("programname3", r.Last().Key);
            Assert.Equal("programDescription3", r.Last().Value);
        }
    }
}