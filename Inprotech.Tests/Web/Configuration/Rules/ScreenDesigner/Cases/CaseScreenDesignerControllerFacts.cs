using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Rules.ScreenDesigner.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.ScreenDesigner.Cases
{
    public class CaseScreenDesignerControllerFacts : FactBase
    {
        public class GetScreenDesignerCriteria : FactBase
        {
            [Fact]
            public void ReturnsCriteriaInformationIfNotInherited()
            {
                var f = new CaseScreenDesignerControllerFixture(Db);

                var criteria = new Criteria()
                {
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    Description = Fixture.String()
                }.In(Db);
                f.PermissionHelper.CanEdit(criteria, out _).Returns(true);

                var r = f.Subject.GetScreenDesignerCriteria(criteria.Id);

                Assert.Equal(r.CriteriaId, criteria.Id);
                Assert.Equal(r.CriteriaName, criteria.Description);
                Assert.Equal(r.IsProtected, criteria.IsProtected);
                Assert.True(r.CanEdit);
            }

            [Fact]
            public void ReturnsHasOfficeIfAnyOffices()
            {
                var f = new CaseScreenDesignerControllerFixture(Db);

                var criteria = new Criteria()
                {
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    Description = Fixture.String()
                }.In(Db);
                new Office(Fixture.Integer(), Fixture.String()).In(Db);

                var r = f.Subject.GetScreenDesignerCriteria(criteria.Id);

                Assert.True(r.HasOffices);
            }

            [Fact]
            public void ReturnsNotHasOfficeIfNotAnyOffices()
            {
                var f = new CaseScreenDesignerControllerFixture(Db);

                var criteria = new Criteria()
                {
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    Description = Fixture.String()
                }.In(Db);

                var r = f.Subject.GetScreenDesignerCriteria(criteria.Id);

                Assert.False(r.HasOffices);
            }
        }

        public class CaseScreenDesignerControllerFixture : IFixture<CaseScreenDesignerController>
        {
            public CaseScreenDesignerControllerFixture(IDbContext dbContext)
            {
                PreferredCulture = Substitute.For<IPreferredCultureResolver>();
                PermissionHelper = Substitute.For<ICaseScreenDesignerPermissionHelper>();
                CaseViewSectionsResolver = Substitute.For<ICaseViewSectionsResolver>();
                Subject = new CaseScreenDesignerController(dbContext, PreferredCulture, PermissionHelper, CaseViewSectionsResolver);
            }

            public ICaseViewSectionsResolver CaseViewSectionsResolver { get; set; }
            public IPreferredCultureResolver PreferredCulture { get; set; }

            public ICaseScreenDesignerPermissionHelper PermissionHelper { get; set; }

            public CaseScreenDesignerController Subject { get; }
        }
    }
}