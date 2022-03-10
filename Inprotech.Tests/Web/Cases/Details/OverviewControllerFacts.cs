using System.Net;
using System.Net.Http;
using System.Reflection;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class OverviewControllerFacts
    {
        public const string CaseViewOverviewTopics = "CaseView.Overview";

        public class GetOverviewMethodFact : FactBase
        {
            [Theory]
            [InlineData(true, true)]
            [InlineData(false, false)]
            [InlineData(false, true)]
            [InlineData(true, false)]
            public void ReturnsOverviewData(bool withRenewalStatus, bool withSameFamilyIdAndTitle)
            {
                var s = new OverviewControllerFixture(Db);
                var familyId = Fixture.String();
                var fam = withSameFamilyIdAndTitle ? new Family(familyId, " " + familyId + string.Empty) : new Family(Fixture.String(), Fixture.String());

                var @case = new CaseBuilder().Build().In(Db);
                var status = new StatusBuilder().Build();
                var renewalStatus = new StatusBuilder().ForRenewal().Build();

                @case.Family = fam;
                @case.CaseStatus = status;
                if (withRenewalStatus)
                {
                    @case.Property = new CaseProperty();
                    @case.Property.SetRenewalStatus(renewalStatus);
                }

                var r = s.Subject.GetCaseOverview(@case.Id);
                Assert.Equal(@case.Id, r.CaseKey);
                Assert.Equal(@case.Title, r.Title);
                Assert.Equal(@case.Irn, r.Irn);
                Assert.True(r.IsDead);
                Assert.False(r.IsPending);
                Assert.False(r.IsRegistered);
                Assert.Equal(withSameFamilyIdAndTitle ? fam.Name : $"{fam.Name} {{{fam.Id}}}", r.Family);

                s.PolicingStatusReader.Received(1).Read(@case.Id);
                s.SiteControlReader.Received(1).Read<bool>(SiteControls.NameVariant);
                s.StatusReader.Received(1).GetCaseStatusSummary(@case);
                s.StatusReader.Received(1).GetCaseStatusDescription(status);
                s.CaseHeaderDescription.Received(1).For(@case.Irn);
                s.DefaultCaseImage.Received(1).For(@case.Id);

                if (withRenewalStatus)
                {
                    s.StatusReader.Received(1).GetCaseStatusDescription(renewalStatus);
                }
                else
                {
                    s.StatusReader.DidNotReceive().GetCaseStatusDescription(renewalStatus);
                    s.StatusReader.Received(1).GetCaseStatusDescription(null);
                }
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ReturnExternalClientData(bool isExternal)
            {
                var s = new OverviewControllerFixture(Db, isExternal);
                var @case = new CaseBuilder().Build().In(Db);
                var yourContact = new NameBuilder(Db).Build();
                var reference = Fixture.String("REF");
                var ourContact = new NameBuilder(Db).Build();

                s.ClientNameDetails.GetDetails(Arg.Any<Case>()).Returns(new ClientAccessDetails {Reference = reference, ExternalContact = yourContact, FirmContact = ourContact});

                var r = s.Subject.GetCaseOverview(@case.Id);
                if (isExternal)
                {
                    s.ClientNameDetails.Received(1).GetDetails(Arg.Any<Case>());
                    Assert.Equal(reference, r.YourReference);
                    Assert.Equal(yourContact.Formatted(), r.ClientMainContact.Name);
                    Assert.Equal(ourContact.Formatted(), r.OurContact.Name);
                }
                else
                {
                    s.ClientNameDetails.DidNotReceiveWithAnyArgs().GetDetails(Arg.Any<Case>());
                }
            }

            [Trait("Category", CaseViewOverviewTopics)]
            [Fact]
            public void CheckCaseStatusFlags()
            {
                var s = new OverviewControllerFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                @case.CaseStatus.RegisteredFlag = 1m;
                @case.CaseStatus.LiveFlag = 1m;

                var r = s.Subject.GetCaseOverview(@case.Id);

                Assert.False(r.IsDead);
                Assert.False(r.IsPending);
                Assert.True(r.IsRegistered);
            }

            [Fact]
            public void OverviewHasAttributeToRegistersCaseAccess()
            {
                var method = typeof(OverviewController).GetMethod(nameof(OverviewController.GetCaseOverview));
                var attribte = method?.GetCustomAttribute<RegisterAccessAttribute>();
                Assert.NotNull(attribte);
            }

            [Fact]
            [Trait("Category", CaseViewOverviewTopics)]
            public void Returns404WhenCaseNotFound()
            {
                var s = new OverviewControllerFixture(Db);

                var response = s.Subject.GetCaseOverview(Fixture.Integer());

                Assert.IsType<HttpResponseMessage>(response);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseMessage) response).StatusCode);
            }

            [Fact]
            public void DoesntErrorOnNoFamilyTitle()
            {
                var s = new OverviewControllerFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);

                @case.Family = new Family("One", "a");
                @case.Family.Name = null;

                var response = s.Subject.GetCaseOverview(@case.Id);
                
                Assert.NotNull(response);
            }
        }

        public class OverviewControllerFixture : IFixture<OverviewController>
        {
            public OverviewControllerFixture(InMemoryDbContext db, bool isExternal = false)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                Basis = Substitute.For<IBasis>();
                StatusReader = Substitute.For<ICaseStatusReader>();
                PropertyTypes = Substitute.For<IPropertyTypes>();
                CaseCategories = Substitute.For<ICaseCategories>();
                SubTypes = Substitute.For<ISubTypes>();
                PolicingStatusReader = Substitute.For<IPolicingStatusReader>();
                PolicingStatusReader.Read(Arg.Any<int>()).Returns(Fixture.String());
                SiteControlReader = Substitute.For<ISiteControlReader>();
                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.ReturnsForAnyArgs(new User("test", isExternal));
                ClientNameDetails = Substitute.For<IClientNameDetails>();
                CaseHeaderDescription = Substitute.For<ICaseHeaderDescription>();
                DefaultCaseImage = Substitute.For<IDefaultCaseImage>();
                SubjectSecurity = Substitute.For<ISubjectSecurityProvider>();
                AuditLogs = Substitute.For<IAuditLogs>();
                Subject = new OverviewController(db, PreferredCultureResolver, Basis, StatusReader, PropertyTypes, CaseCategories, SubTypes, PolicingStatusReader, SiteControlReader, SecurityContext, ClientNameDetails, CaseHeaderDescription, DefaultCaseImage, SubjectSecurity, AuditLogs);
            }
            public ISubjectSecurityProvider SubjectSecurity { get; set; }
            public IClientNameDetails ClientNameDetails { get; set; }
            public IAuditLogs AuditLogs { get; }
            public IPreferredCultureResolver PreferredCultureResolver { get; }
            public IBasis Basis { get; }
            public ICaseStatusReader StatusReader { get; }
            public IPropertyTypes PropertyTypes { get; }
            public ICaseCategories CaseCategories { get; }
            public ISubTypes SubTypes { get; }
            public IPolicingStatusReader PolicingStatusReader { get; set; }
            public ISiteControlReader SiteControlReader { get; set; }
            public ISecurityContext SecurityContext { get; set; }
            public ICaseHeaderDescription CaseHeaderDescription { get; set; }
            public IDefaultCaseImage DefaultCaseImage { get; set; }

            public OverviewController Subject { get; }
        }
    }
}