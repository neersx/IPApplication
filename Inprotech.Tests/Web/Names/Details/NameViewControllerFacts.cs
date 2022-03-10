using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Common;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Names.Details;
using Inprotech.Web.Search;
using InprotechKaizen.Model.Components.Names.Screens;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;
using Program = InprotechKaizen.Model.Security.Program;

namespace Inprotech.Tests.Web.Names.Details
{
    public class NameViewControllerFacts
    {
        public class NameViewControllerFixture : IFixture<NameViewController>
        {
            public NameViewControllerFixture(InMemoryDbContext db)
            {
                SecurityContext = Substitute.For<ISecurityContext>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                NameViewSectionsResolver = Substitute.For<INameViewSectionsResolver>();
                NameViewSectionsResolver.Resolve(Arg.Any<int>(), Arg.Any<string>()).Returns(Task.FromResult(new NameViewSections()));
                NameViewResolver = Substitute.For<INameViewResolver>();
                SupplierDetailsMaintenance = Substitute.For<ISupplierDetailsMaintenance>();
                TrustAccountingResolver = Substitute.For<ITrustAccountingResolver>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                ListPrograms = Substitute.For<IListPrograms>();
                Subject = new NameViewController(db, SecurityContext, SiteControlReader, NameViewSectionsResolver, NameViewResolver, SupplierDetailsMaintenance, TrustAccountingResolver, TaskSecurityProvider, ListPrograms);
            }

            public NameViewController Subject { get; set; }
            public ISecurityContext SecurityContext { get; set; }
            public ISiteControlReader SiteControlReader { get; set; }
            public INameViewSectionsResolver NameViewSectionsResolver { get; set; }
            public INameViewResolver NameViewResolver { get; set; }
            public ISupplierDetailsMaintenance SupplierDetailsMaintenance { get; set; }
            public ITrustAccountingResolver TrustAccountingResolver { get; set; }
            public ITaskSecurityProvider TaskSecurityProvider { get; set; }
            public IListPrograms ListPrograms { get; set; }
            public Program ProgramFromProfile { get; set; }
            
            public NameViewControllerFixture WithSections(NameViewSections sections)
            {
                NameViewSectionsResolver.Resolve(Arg.Any<int>(), Arg.Any<string>()).Returns(Task.FromResult(sections));

                return this;
            }

            public NameViewControllerFixture WithProgram(InMemoryDbContext db, bool withProfile = false)
            {
                new Program {Id = "DEFAULT", Name = "Default Name Program"}.In(db);
                var programForProfile = new Program {Id = "NEW", Name = "New Name Program"}.In(db);
                new Program {Id = "UNUSED", Name = "Unused Name Program"}.In(db);

                if (withProfile)
                {
                    var profile = new Profile(Fixture.Integer(), Fixture.String()).In(db);
                    new ProfileProgram(profile.Id, programForProfile).In(db);
                    var user = new User(Fixture.UniqueName(), false, profile).In(db);
                    SecurityContext.User.Returns(user);
                }

                var siteControl = new SiteControlBuilder {SiteControlId = SiteControls.NameScreenDefaultProgram, StringValue = "DEFAULT"}.Build().In(db);

                SiteControlReader.Read<string>(SiteControls.NameScreenDefaultProgram).Returns(siteControl.StringValue);
                ListPrograms.GetDefaultNameProgram().Returns("DEFAULT");
                
                return this;
            }
        }

        public class GetNameViewMethod : FactBase
        {
            [Fact]
            public async Task ReturnsCorrectNameDetails()
            {
                var name = new NameBuilder(Db).Build().In(Db);
                var sections = new NameViewSections
                {
                    ScreenNameCriteria = Fixture.Integer(),
                    Sections = new List<NameViewSection>()
                };
                var f = new NameViewControllerFixture(Db).WithProgram(Db).WithSections(sections);
                var r = await f.Subject.GetNameView(name.Id);

                Assert.Equal(name.NameCode, r.NameCode);
                Assert.Equal(sections.ScreenNameCriteria, r.NameCriteriaId);
            }

            [Theory]
            [InlineData(false, false, "Default Name Program")]
            [InlineData(false, true, "Default Name Program")]
            [InlineData(true, false, "New Name Program")]
            [InlineData(true, true, "Default Name Program")]
            public async Task ReturnsNameDetailsForCorrectProgram(bool withProfile, bool asInvalid, string expected)
            {
                var name = new NameBuilder(Db).Build().In(Db);
                var sections = new NameViewSections
                {
                    ScreenNameCriteria = Fixture.Integer(),
                    Sections = new List<NameViewSection>()
                };
                var f = new NameViewControllerFixture(Db).WithProgram(Db, withProfile).WithSections(sections);
                var r = await f.Subject.GetNameView(name.Id, asInvalid ? "UNUSED" : "NEW");

                Assert.Equal(name.NameCode, r.NameCode);
                Assert.Equal(sections.ScreenNameCriteria, r.NameCriteriaId);
                Assert.Equal(expected, r.Program);
            }
            
            [Fact]
            public async Task ShouldReturnCanGenerateWordDocumentIfHasTaskSecurity()
            {
                var name = new NameBuilder(Db).Build().In(Db);
                var f = new NameViewControllerFixture(Db);
                f.WithProgram(Db);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.CreateMsWordDocument).Returns(true);

                var r = await f.Subject.GetNameView(name.Id);

                Assert.True(r.CanGenerateWordDocument);
            }

            [Fact]
            public async Task ShouldReturnCantGenerateWordDocumentIfNoTaskSecurity()
            {
                var name = new NameBuilder(Db).Build().In(Db);
                var f = new NameViewControllerFixture(Db);
                f.WithProgram(Db);

                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.CreateMsWordDocument).Returns(false);

                var r = await f.Subject.GetNameView(name.Id);

                Assert.False(r.CanGenerateWordDocument);
            }
            
            [Fact]
            public async Task ShouldReturnCanGeneratePdfDocumentIfHasTaskSecurity()
            {
                var name = new NameBuilder(Db).Build().In(Db);
                var f = new NameViewControllerFixture(Db);
                f.WithProgram(Db);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.CreatePdfDocument).Returns(true);
                f.SiteControlReader.Read<bool>(SiteControls.PDFFormFilling).Returns(true);
                var r = await f.Subject.GetNameView(name.Id);

                Assert.True(r.CanGeneratePdfDocument);
            }

            [Fact]
            public async Task ShouldReturnCantGeneratePdfDocumentIfNoTaskSecurity()
            {
                var name = new NameBuilder(Db).Build().In(Db);
                var f = new NameViewControllerFixture(Db);
                f.WithProgram(Db);

                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.CreatePdfDocument).Returns(false);

                var r = await f.Subject.GetNameView(name.Id);

                Assert.False(r.CanGeneratePdfDocument);
            }

            [Fact]
            public async Task ShouldReturnCantGeneratePdfDocumentIfNoSiteControlSet()
            {
                var name = new NameBuilder(Db).Build().In(Db);
                var f = new NameViewControllerFixture(Db);
                f.WithProgram(Db);

                f.SiteControlReader.Read<bool>(SiteControls.PDFFormFilling).Returns(false);

                var r = await f.Subject.GetNameView(name.Id);

                Assert.False(r.CanGeneratePdfDocument);
            }
        }

        public class GetTrustAccountingData : FactBase
        {
            [Fact]
            public async Task VerifyTrustAccountingDataWithValidParams()
            {
                var name = new NameBuilder(Db).Build().In(Db);
                var request = new CommonQueryParameters { Skip = 0, Take = 10 };
                var fixture = new NameViewControllerFixture(Db);
                var trustAccountingList = new List<TrustAccountingData> { new TrustAccountingData { LocalBalance = (decimal)1.0 }, new TrustAccountingData { LocalBalance = (decimal)2.0 } };

                fixture.TrustAccountingResolver.Resolve(name.Id, request)
                 .Returns(new ResultResponse
                 {
                     Result = new PagedResults(trustAccountingList, 2),
                     TotalLocalBalance = (decimal)3.0
                 });
                var result = await fixture.Subject.GetTrustAccountingData(name.Id, request);
                Assert.NotNull(result);

                await fixture.TrustAccountingResolver.Received(1).Resolve(name.Id, request);
            }
        }
    }
}