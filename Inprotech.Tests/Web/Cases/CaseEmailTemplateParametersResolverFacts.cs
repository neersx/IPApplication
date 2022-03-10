using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases
{
    public class CaseEmailTemplateParametersResolverFacts : FactBase
    {
        public CaseEmailTemplateParametersResolverFacts()
        {
            var @case = new CaseBuilder().Build().In(Db);
            var nameType = new NameTypeBuilder { NameTypeCode = Fixture.String() }.Build().In(Db);
            var email1 = new TelecommunicationBuilder { TelecomNumber = "marvell@abc.com" }.Build().In(Db);
            var email2 = new TelecommunicationBuilder { TelecomNumber = "tonystark@starkinc.com" }.Build().In(Db);
            var name1 = new NameBuilder(Db) { Email = email1 }.Build().In(Db);
            var name2 = new NameBuilder(Db) { Email = email2 }.Build().In(Db);
            _caseName1 = new CaseNameBuilder(Db)
            {
                Case = @case,
                NameType = nameType,
                Name = name1,
                Sequence = 1
            }.Build().In(Db);
            new CaseNameBuilder(Db)
            {
                Case = @case,
                NameType = nameType,
                Name = name2,
                Sequence = 2
            }.Build().In(Db);
            _caseId = @case.Id;
            _nameType = nameType.NameTypeCode;
            _email1 = email1.TelecomNumber;
            _email2 = email2.TelecomNumber;
        }

        public class CaseEmailTemplateParametersResolverFixture : IFixture<CaseEmailTemplateParametersResolver>
        {
            public CaseEmailTemplateParametersResolverFixture(InMemoryDbContext db, bool isExternalUser = false)
            {
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(new User(Fixture.String(), isExternalUser));

                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                EmailValidator = Substitute.For<IEmailValidator>();

                Subject = new CaseEmailTemplateParametersResolver(db, securityContext, TaskSecurityProvider, EmailValidator, Fixture.Today);
            }

            public ITaskSecurityProvider TaskSecurityProvider { get; }

            public IEmailValidator EmailValidator { get; }

            public CaseEmailTemplateParametersResolver Subject { get; }

            public CaseEmailTemplateParametersResolverFixture WithTaskSecurity(ApplicationTask task)
            {
                TaskSecurityProvider.HasAccessTo(task).Returns(true);
                return this;
            }

            public CaseEmailTemplateParametersResolverFixture WithEmailValidated(string email = null)
            {
                if (email == null)
                {
                    EmailValidator.IsValid(Arg.Any<string>()).Returns(true);
                }
                else
                {
                    EmailValidator.IsValid(email).Returns(true);
                }

                return this;
            }
        }

        readonly int _caseId;
        readonly string _nameType;
        readonly CaseName _caseName1;
        readonly string _email1;
        readonly string _email2;

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ShouldPreventCheckingIfAccessNotAvailable(bool externalUser)
        {
            var fixture = new CaseEmailTemplateParametersResolverFixture(Db, externalUser);

            await fixture.Subject.Resolve(new CaseNameEmailTemplateParameters
            {
                CaseKey = _caseId,
                NameType = _nameType
            });

            fixture.EmailValidator.DidNotReceive().IsValid(Arg.Any<string>());
        }

        [Theory]
        [InlineData(ApplicationTask.EmailOurCaseContact, true)]
        [InlineData(ApplicationTask.EmailCaseResponsibleStaff, false)]
        public async Task ShouldResolveEmailFromCaseName(ApplicationTask task, bool isExternalUser)
        {
            var fixture = new CaseEmailTemplateParametersResolverFixture(Db, isExternalUser)
                          .WithTaskSecurity(task)
                          .WithEmailValidated();

            var r = await fixture.Subject.Resolve(new CaseNameEmailTemplateParameters
            {
                CaseKey = _caseId,
                NameType = _nameType
            });

            Assert.Contains(r, x => x.NameType == _nameType && x.CaseKey == _caseId && x.Sequence == 1 && x.CaseNameMainEmail == _email1);
            Assert.Contains(r, x => x.NameType == _nameType && x.CaseKey == _caseId && x.Sequence == 2 && x.CaseNameMainEmail == _email2);
        }

        [Theory]
        [InlineData(ApplicationTask.EmailOurCaseContact, true)]
        [InlineData(ApplicationTask.EmailCaseResponsibleStaff, false)]
        public async Task ShouldResolveForCurrentNamesOnly(ApplicationTask task, bool isExternalUser)
        {
            var fixture = new CaseEmailTemplateParametersResolverFixture(Db, isExternalUser)
                          .WithTaskSecurity(task)
                          .WithEmailValidated();

            _caseName1.ExpiryDate = Fixture.PastDate();

            var r = await fixture.Subject.Resolve(new CaseNameEmailTemplateParameters
            {
                CaseKey = _caseId,
                NameType = _nameType
            });

            Assert.Equal(r.Single().CaseNameMainEmail, _email2);
        }

        [Fact]
        public async Task ShouldNotReturnInvalidEmails()
        {
            var fixture = new CaseEmailTemplateParametersResolverFixture(Db)
                .WithTaskSecurity(ApplicationTask.EmailCaseResponsibleStaff);

            var r = await fixture.Subject.Resolve(new CaseNameEmailTemplateParameters
            {
                CaseKey = _caseId,
                NameType = _nameType
            });

            Assert.Empty(r);
        }

        [Fact]
        public async Task ShouldReturnThoseWithEmailsOnly()
        {
            var fixture = new CaseEmailTemplateParametersResolverFixture(Db)
                .WithTaskSecurity(ApplicationTask.EmailCaseResponsibleStaff)
                .WithEmailValidated();

            _caseName1.Name.MainEmailId = null;

            var r = await fixture.Subject.Resolve(new CaseNameEmailTemplateParameters
            {
                CaseKey = _caseId,
                NameType = _nameType
            });

            Assert.Equal(r.Single().CaseNameMainEmail, _email2);
        }

        [Fact]
        public async Task ShouldReturnBySpecificSequence()
        {
            var fixture = new CaseEmailTemplateParametersResolverFixture(Db)
                .WithTaskSecurity(ApplicationTask.EmailCaseResponsibleStaff)
                .WithEmailValidated();

            var r = await fixture.Subject.Resolve(new CaseNameEmailTemplateParameters
            {
                CaseKey = _caseId,
                NameType = _nameType,
                Sequence = 2
            });

            Assert.Equal(r.Single().CaseNameMainEmail, _email2);
        }
    }
}