using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Cases;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Search;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseViewControllerFacts
    {
        public class GetCaseImportanceLevelsAndNoteTypes : FactBase
        {
            readonly int defaultImportanceLevel = 5;
            readonly int importanceLevelCount = 6;

            [Fact]
            public async Task RequireImportanceLevelOnlyForExternalUser()
            {
                var f = new CaseViewControllerFixture(Db)
                    .WithUser();
                Assert.False((await f.Subject.GetCaseImportanceLevelsAndNoteTypes()).RequireImportanceLevel);

                f = new CaseViewControllerFixture(Db).WithUser(true);
                Assert.True((await f.Subject.GetCaseImportanceLevelsAndNoteTypes()).RequireImportanceLevel);
            }

            [Fact]
            public async Task ViewFiltersDataForExternalUser()
            {
                var f = new CaseViewControllerFixture(Db).WithUser(true)
                                                         .WithDefaultImportanceLevel(defaultImportanceLevel)
                                                         .WithImportanceLevelOptions(importanceLevelCount);

                var r = await f.Subject.GetCaseImportanceLevelsAndNoteTypes();

                Assert.Equal(defaultImportanceLevel, r.ImportanceLevel);
                Assert.Single(((IEnumerable<dynamic>)r.ImportanceLevelOptions).ToArray());
                Assert.DoesNotContain((IEnumerable<dynamic>)r.ImportanceLevelOptions, _ => _.Code < defaultImportanceLevel);
                Assert.True(r.RequireImportanceLevel);
            }

            [Fact]
            public async Task ViewReturnsDataForInternalUser()
            {
                var f = new CaseViewControllerFixture(Db).WithDefaultImportanceLevel(defaultImportanceLevel)
                                                         .WithImportanceLevelOptions(importanceLevelCount)
                                                         .WithNoteTypes()
                                                         .WithUser();

                var r = await f.Subject.GetCaseImportanceLevelsAndNoteTypes();

                Assert.Equal(defaultImportanceLevel, r.ImportanceLevel);
                Assert.Equal(importanceLevelCount, ((IEnumerable<dynamic>)r.ImportanceLevelOptions).ToArray().Length);
                Assert.False(r.RequireImportanceLevel);
                Assert.Equal(2, ((IEnumerable<NotesTypeData>)r.EventNoteTypes).ToArray().Length);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ViewReturnsPermissionForAddAttachment(bool hasPermission)
            {
                var f = hasPermission
                    ? new CaseViewControllerFixture(Db).WithTaskSecurity(ApplicationTask.MaintainCaseAttachments, ApplicationTaskAccessLevel.Create)
                                                       .WithUser()
                    : new CaseViewControllerFixture(Db).WithUser();

                var r = await f.Subject.GetCaseImportanceLevelsAndNoteTypes();

                Assert.Equal(hasPermission, r.CanAddCaseAttachments);
            }
        }

        class CaseViewControllerFixture : IFixture<CaseViewController>
        {
            readonly ICaseEmailTemplate _caseEmailTemplate;
            readonly IConfigurationSettings _configurationSettings;
            readonly InMemoryDbContext _db;
            readonly IEventNotesResolver _eventNotesResolver;
            readonly IImportanceLevelResolver _importanceLevelResolver;
            readonly IListPrograms _listCasePrograms;
            readonly IPreferredCultureResolver _preferredCultureResolver;
            readonly ISecurityContext _securityContext;
            public ISiteControlReader SiteControlReader { get; }
            readonly ITaskSecurityProvider _taskSecurityProvider;
            public readonly ICaseAuthorization _caseAuthorization;

            public CaseViewControllerFixture(InMemoryDbContext db)
            {
                _securityContext = Substitute.For<ISecurityContext>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                _importanceLevelResolver = Substitute.For<IImportanceLevelResolver>();
                _eventNotesResolver = Substitute.For<IEventNotesResolver>();
                _caseEmailTemplate = Substitute.For<ICaseEmailTemplate>();
                _configurationSettings = Substitute.For<IConfigurationSettings>();
                _preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                _listCasePrograms = Substitute.For<IListPrograms>();
                _caseAuthorization = Substitute.For<ICaseAuthorization>();
                _db = db;
                _taskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                var subjectSecurityProvider = Substitute.For<ISubjectSecurityProvider>();
                Subject = new CaseViewController(_securityContext, SiteControlReader, _importanceLevelResolver, _eventNotesResolver, _configurationSettings,
                                                 _caseEmailTemplate, _taskSecurityProvider, db, _preferredCultureResolver, _listCasePrograms, subjectSecurityProvider, _caseAuthorization);
            }

            public User User { get; private set; }

            public CaseViewController Subject { get; }

            public CaseViewControllerFixture WithUser(bool isExternal = false)
            {
                User = new User(Fixture.String(), isExternal) { Name = new NameBuilder(_db).Build() };
                _securityContext.User.Returns(User);
                return this;
            }

            public CaseViewControllerFixture WithSiteControlValue(string clientNumberTypeValue = null, bool? keepTextHistoryValue = null)
            {
                SiteControlReader.Read<string>(SiteControls.ClientNumberTypesShown).Returns(clientNumberTypeValue);
                SiteControlReader.Read<bool?>(SiteControls.KEEPSPECIHISTORY).Returns(keepTextHistoryValue);
                return this;
            }

            public CaseViewControllerFixture WithRFIDSystem()
            {
                SiteControlReader.Read<bool>(SiteControls.RFIDSystem).Returns(true);
                return this;
            }

            public CaseViewControllerFixture WithTaskSecurity(ApplicationTask task)
            {
                _taskSecurityProvider.HasAccessTo(task).Returns(true);
                return this;
            }

            public CaseViewControllerFixture WithTaskSecurity(ApplicationTask task, ApplicationTaskAccessLevel level)
            {
                _taskSecurityProvider.HasAccessTo(task, level).Returns(true);
                return this;
            }

            public CaseViewControllerFixture WithDefaultImportanceLevel(int defaultImportanceLevel)
            {
                _importanceLevelResolver.Resolve().Returns(defaultImportanceLevel);
                return this;
            }

            public CaseViewControllerFixture WithImportanceLevelOptions(int totalImportanceLevels)
            {
                var importance = new List<Importance>();
                Enumerable.Range(0, totalImportanceLevels).ToList().ForEach(i => { importance.Add(new Importance(i.ToString(), $"Importance Level {i}")); });
                _importanceLevelResolver.GetImportanceLevels().Returns(Task.FromResult(importance.AsEnumerable()));
                return this;
            }

            public CaseViewControllerFixture WithNoteTypes()
            {
                var notes = new[]
                {
                    new NotesTypeData {Code = 1, Description = Fixture.String(), IsDefault = true},
                    new NotesTypeData {Code = 2, Description = Fixture.String()}
                }.AsQueryable();
                _eventNotesResolver.EventNoteTypesWithDefault().Returns(notes);
                return this;
            }

            public CaseViewControllerFixture ResolvedFromDataItem(string recipient = null, string subject = null, string body = null)
            {
                _caseEmailTemplate.ForCase(Arg.Any<int>())
                                  .Returns(new EmailTemplate
                                  {
                                      RecipientEmail = recipient,
                                      Subject = subject,
                                      Body = body
                                  });

                return this;
            }

            public CaseViewControllerFixture WithWebConfigContactUsEmail(string email)
            {
                _configurationSettings[KnownAppSettingsKeys.ContactUsEmailAddress].Returns(email);

                return this;
            }

            public CaseViewControllerFixture WithPrograms()
            {
                _preferredCultureResolver.Resolve().Returns(Fixture.String());
                new Program("casentry", "Case").In(_db);
                new Program("casenquiry", "Case Enquiry").In(_db);
                return this;
            }

            public CaseViewControllerFixture WithDefaultProgram()
            {
                _listCasePrograms.GetDefaultCaseProgram().Returns("casentry");
                return this;
            }
        }

        public class GetCaseViewPermissionsMethod : FactBase
        {
            [Fact]
            public async Task ExternalUserCanNotViewOtherNumbersIfSiteControlHasNoValue()
            {
                var f = new CaseViewControllerFixture(Db).WithUser(true).WithSiteControlValue();
                var r = await f.Subject.GetCaseViewPermissions();

                Assert.False(r.CanViewOtherNumbers);
            }

            [Fact]
            public async Task ExternalUserCanViewOtherNumbersIfSiteControlHasValue()
            {
                var f = new CaseViewControllerFixture(Db).WithUser(true).WithSiteControlValue("ab,cd");
                var r = await f.Subject.GetCaseViewPermissions();

                Assert.True(r.CanViewOtherNumbers);
            }

            [Fact]
            public async Task InternalUserCanViewOtherNumbers()
            {
                var f = new CaseViewControllerFixture(Db).WithUser();
                var r = await f.Subject.GetCaseViewPermissions();

                Assert.True(r.CanViewOtherNumbers);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ShouldReturnSiteControlValueForKeepSpecHistory(bool val)
            {
                var f = new CaseViewControllerFixture(Db).WithUser(true).WithSiteControlValue(keepTextHistoryValue: val);
                var r = await f.Subject.GetCaseViewPermissions();

                Assert.Equal(val, r.KeepSpecHistory);
            }

            [Fact]
            public async Task ShouldReturnCanCreateCaseFileIfHasTaskPermissions()
            {
                var f = new CaseViewControllerFixture(Db).WithUser(true).WithTaskSecurity(ApplicationTask.MaintainFileTracking, ApplicationTaskAccessLevel.Create);
                var r = await f.Subject.GetCaseViewPermissions();

                Assert.True(r.CanCreateCaseFile);
            }

            [Fact]
            public async Task ShouldReturnCanDeleteCaseFileIfHasTaskPermissions()
            {
                var f = new CaseViewControllerFixture(Db).WithUser(true).WithTaskSecurity(ApplicationTask.MaintainFileTracking, ApplicationTaskAccessLevel.Delete);
                var r = await f.Subject.GetCaseViewPermissions();

                Assert.True(r.CanDeleteCaseFile);
            }

            [Fact]
            public async Task ShouldReturnCanGenerateWordDocumentIfHasTaskPermissions()
            {
                var f = new CaseViewControllerFixture(Db).WithUser(true).WithTaskSecurity(ApplicationTask.CreateMsWordDocument);
                var r = await f.Subject.GetCaseViewPermissions();

                Assert.True(r.CanGenerateWordDocument);
            }

            [Fact]
            public async Task ShouldReturnCanGeneratePdfDocumentIfHasTaskPermissions()
            {
                var f = new CaseViewControllerFixture(Db).WithUser(true).WithTaskSecurity(ApplicationTask.CreatePdfDocument);
                f.SiteControlReader.Read<bool>(SiteControls.PDFFormFilling).Returns(true);

                var r = await f.Subject.GetCaseViewPermissions();

                Assert.True(r.CanGeneratePdfDocument);
            }

            [Fact]
            public async Task ShouldReturnCanMaintainCaseIfHasTaskPermissions()
            {
                var f = new CaseViewControllerFixture(Db).WithUser(true).WithTaskSecurity(ApplicationTask.MaintainCase, ApplicationTaskAccessLevel.Modify);
                var r = await f.Subject.GetCaseViewPermissions();

                Assert.True(r.CanMaintainCase);
            }

            [Fact]
            public async Task ShouldReturnCanRequestCaseFileIfHasTaskPermissionsAndRfIdSystem()
            {
                var f = new CaseViewControllerFixture(Db).WithUser(true).WithTaskSecurity(ApplicationTask.MaintainFileTracking).WithSiteControlValue().WithRFIDSystem();
                var r = await f.Subject.GetCaseViewPermissions();

                Assert.True(r.CanRequestCaseFile);
            }

            [Fact]
            public async Task ShouldReturnCanRequestCaseFileIfNotRfIdSystem()
            {
                var f = new CaseViewControllerFixture(Db).WithUser(true).WithTaskSecurity(ApplicationTask.MaintainFileTracking).WithSiteControlValue();
                var r = await f.Subject.GetCaseViewPermissions();

                Assert.False(r.CanRequestCaseFile);
            }

            [Fact]
            public async Task ShouldReturnCantCreateCaseFileIfHasNoTaskPermissions()
            {
                var f = new CaseViewControllerFixture(Db).WithUser(true);
                var r = await f.Subject.GetCaseViewPermissions();

                Assert.False(r.CanCreateCaseFile);
                Assert.False(r.CanDeleteCaseFile);
                Assert.False(r.CanGenerateWordDocument);
                Assert.False(r.CanGeneratePdfDocument);
                Assert.False(r.CanMaintainCase);
                Assert.False(r.CanRequestCaseFile);
                Assert.False(r.CanUpdateCaseFile);
                Assert.Equal(f.User.Name.Id, r.NameId);
            }

            [Fact]
            public async Task ShouldReturnCanUpdateCaseFileIfHasTaskPermissions()
            {
                var f = new CaseViewControllerFixture(Db).WithUser(true).WithTaskSecurity(ApplicationTask.MaintainFileTracking, ApplicationTaskAccessLevel.Modify);
                var r = await f.Subject.GetCaseViewPermissions();

                Assert.True(r.CanUpdateCaseFile);
            }
        }

        public class SupportMethod : FactBase
        {
            [Theory]
            [InlineData("contact-us@cpaglobal.com", "helpdesk@cpaglobal.com", "Regarding: 1234/A", "Regarding: 1234/A Rondon Shoes", "mailto:helpdesk@cpaglobal.com?subject=Regarding: 1234%2FA&body=Regarding: 1234%2FA Rondon Shoes")]
            [InlineData("contact-us@cpaglobal.com", "helpdesk@cpaglobal.com", null, "Regarding: 1234/A Rondon Shoes", "mailto:helpdesk@cpaglobal.com?body=Regarding: 1234%2FA Rondon Shoes")]
            [InlineData("contact-us@cpaglobal.com", "helpdesk@cpaglobal.com", "Regarding: 1234/A", null, "mailto:helpdesk@cpaglobal.com?subject=Regarding: 1234%2FA")]
            [InlineData("contact-us@cpaglobal.com", null, "Regarding: 1234/A", "Regarding: 1234/A Rondon Shoes", "mailto:contact-us@cpaglobal.com?subject=Regarding: 1234%2FA&body=Regarding: 1234%2FA Rondon Shoes")]
            [InlineData(null, null, null, null, "mailto:")]
            [InlineData(null, null, "Regarding: 1234/A", "Regarding: 1234/A Rondon Shoes", "mailto:?subject=Regarding: 1234%2FA&body=Regarding: 1234%2FA Rondon Shoes")]
            public async Task ResolvesEmailCorrespondingly(string contactUsEmail, string recipient, string subject, string body, string expected)
            {
                var f = new CaseViewControllerFixture(Db)
                        .WithWebConfigContactUsEmail(contactUsEmail)
                        .ResolvedFromDataItem(recipient, subject, body);

                var r = await f.Subject.Support(Fixture.Integer());
                var uriString = HttpUtility.UrlDecode(r.Uri.ToString());
                expected = HttpUtility.UrlDecode(expected);
                Assert.Equal(expected, uriString);
            }
        }

        public class GetCaseProgramMethod : FactBase
        {
            [Theory]
            [InlineData("casentry", "Case")]
            [InlineData("casenquiry", "Case Enquiry")]
            [InlineData("", "Case")]
            public async Task RetreivesCaseProgramName(string programId, string expected)
            {
                var f = new CaseViewControllerFixture(Db).WithPrograms().WithDefaultProgram();
                var r = await f.Subject.GetProgram(programId);
                Assert.Equal(expected, r);
            }

            [Fact]
            public async Task RetreivesCaseProgramNameAsNull()
            {
                var f = new CaseViewControllerFixture(Db).WithPrograms();
                var r = await f.Subject.GetProgram(string.Empty);
                Assert.Null(r);
            }
        }
        public class GetCaseId : FactBase
        {
            [Fact]
            public async Task GetCaseIdFromIrn()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var f = new CaseViewControllerFixture(Db);
                f._caseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Select).Returns(Task.FromResult(new AuthorizationResult(@case.Id, true, false, null)));

                var r = await f.Subject.GetCaseReference(@case.Irn);
                Assert.Equal(@case.Id, r);
            }
            
            [Fact]
            public async Task GetCaseIdFromIrnNotExist()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var f = new CaseViewControllerFixture(Db);
                f._caseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Select).Returns(Task.FromResult(new AuthorizationResult(@case.Id, false, false, null)));

                await Assert.ThrowsAsync<InvalidOperationException>(
                                                                async () =>await f.Subject.GetCaseReference(@case.Irn));
            }
            
            [Fact]
            public async Task GetCaseIdFromIrnNotAuthorized()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var f = new CaseViewControllerFixture(Db);
                f._caseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Select).Returns(Task.FromResult(new AuthorizationResult(@case.Id, true, true, "invalid")));

                await Assert.ThrowsAsync<DataSecurityException>(
                                                                async () =>await f.Subject.GetCaseReference(@case.Irn));
            }
        }
    }
}