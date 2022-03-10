using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Search.Case;
using Inprotech.Web.Search.Case.CaseSearch;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Queries;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.CaseSearch
{
    public class CaseSearchViewControllerFacts
    {
        public class GetMethod : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ReturnsSupportData(bool isExternal)
            {
                var f = new CaseSearchViewControllerFixture(Db, isExternal);

                var numberType1 = new NumberTypeBuilder { IssuedByIpOffice = true }.Build().In(Db);
                var numberType2 = new NumberTypeBuilder { IssuedByIpOffice = true }.Build().In(Db);
                var numberType3 = new NumberTypeBuilder { IssuedByIpOffice = false }.Build().In(Db);

                var nameType1 = new NameTypeBuilder().Build().In(Db);
                var nameType2 = new NameTypeBuilder().Build().In(Db);

                var textType = new TextTypeBuilder().Build().In(Db);

                var cpaSend = new CpaSend { PropertyType = "P", BatchNo = 22 }.In(Db);

                new ImportanceBuilder { ImportanceLevel = "1" }.Build().In(Db);
                new ImportanceBuilder { ImportanceLevel = "2" }.Build().In(Db);
                new ImportanceBuilder { ImportanceLevel = "3" }.Build().In(Db);

                new EventNoteType { Description = Fixture.String(), IsExternal = false }.In(Db);

                var entitySize1 = new TableCodeBuilder{TableType = (short)TableTypes.EntitySize}.Build().In(Db);
                var entitySize2 = new TableCodeBuilder{TableType = (short)TableTypes.EntitySize}.Build().In(Db);

                f.UserFilteredTypes.NameTypes().Returns(new[] { nameType1, nameType2 }.AsQueryable());
                f.UserFilteredTypes.NumberTypes().Returns(new[] { numberType1, numberType2 }.AsQueryable());
                f.UserFilteredTypes.TextTypes(true).Returns(new[] { textType });
                f.CaseAttributes.Get().Returns(new List<KeyValuePair<string, string>> { new KeyValuePair<string, string>("1", "Abc") });
                new QueryDataItem { ProcedureItemId = "FirmElementId", ProcedureName = "csw_ListCase", DataFormatId = 9100, IsMultiResult = false, DataItemId = int.MaxValue }.In(Db);

                f.InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).Returns(true);
                f.SiteControlReader.Read<bool>(SiteControls.DisplayCeasedNames).Returns(true);

                var result = f.Subject.Get();
                var numberTypes = ((IEnumerable<dynamic>)result.NumberTypes).Select(_ => (string)_.Value).ToArray();
                var nameTypes = ((IEnumerable<dynamic>)result.NameTypes).Select(_ => (string)_.Value).ToArray();
                var textTypes = ((IEnumerable<dynamic>)result.TextTypes).Select(_ => (string)_.Value).ToArray();
                var importanceOptions = ((IEnumerable<KeyValuePair<string, string>>)result.ImportanceOptions).ToArray();
                var entitySizes = ((IEnumerable<dynamic>)result.EntitySizes).Select(_ => (string)_.Value).ToArray();

                var cpaSends = result.SentToCpaBatchNo;

                Assert.Equal(isExternal, result.IsExternal);
                f.UserFilteredTypes.Received(1).NameTypes();
                f.UserFilteredTypes.Received(1).NumberTypes();
                f.UserFilteredTypes.Received(1).TextTypes(true);
                f.CaseAttributes.Received(1).Get();

                Assert.Contains(numberType1.Name, numberTypes);
                Assert.Contains(numberType2.Name, numberTypes);
                Assert.DoesNotContain(numberType3.Name, numberTypes);
                Assert.Contains(nameType1.Name, nameTypes);
                Assert.Contains(nameType2.Name, nameTypes);
                Assert.Contains(textType.TextDescription, textTypes);
                Assert.True(cpaSends[0].BatchNo.Equals(cpaSend.BatchNo));
                Assert.Equal(result.Attributes[0].Key, "1");
                Assert.Equal(result.Attributes[0].Value, "Abc");
                Assert.True(result.DesignElementTopicVisible);
                Assert.True(result.AllowMultipleCaseTypeSelection);
                Assert.Equal(0, importanceOptions.Length);
                Assert.True(result.ShowCeasedNames);
                Assert.Equal(result.ShowEventNoteType, !isExternal);
                Assert.Equal(result.ShowEventNoteSection, !isExternal);
                Assert.Equal(2, entitySizes.Length);
                Assert.Contains(entitySize1.Name, entitySizes);
                Assert.Contains(entitySize2.Name, entitySizes);
            }

            [Theory]
            [InlineData(true, true)]
            [InlineData(false, true)]
            [InlineData(false, false)]
            [InlineData(true, false)]
            public void ShouldSetEventNoteTypeAndEventNoteSectionBasedOnSiteControlAndPublicEventNoteType(bool allowEventTextForClient, bool hasPublicEventNoteType)
            {
                var f = new CaseSearchViewControllerFixture(Db, true);

                new EventNoteType { Description = Fixture.String(), IsExternal = hasPublicEventNoteType }.In(Db);

                f.SiteControlReader.Read<bool>(SiteControls.ClientEventText).Returns(allowEventTextForClient);

                var result = f.Subject.Get();

                Assert.Equal(result.ShowEventNoteType, hasPublicEventNoteType);
                Assert.Equal(result.ShowEventNoteSection, allowEventTextForClient || hasPublicEventNoteType);
            }
        }

        public class CaseSearchViewControllerFixture : IFixture<CaseSearchViewController>
        {
            public CaseSearchViewControllerFixture(InMemoryDbContext db, bool forExternal = false)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.Returns(new UserBuilder(db) { IsExternalUser = forExternal }.Build());
                UserFilteredTypes = Substitute.For<IUserFilteredTypes>();
                CaseAttributes = Substitute.For<ICaseAttributes>();
                InprotechVersionChecker = Substitute.For<IInprotechVersionChecker>();
                CaseSavedSearch = Substitute.For<ICaseSavedSearch>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                SearchService = Substitute.For<ICaseSearchService>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

                SearchService.DueDatePresentationColumn(Arg.Any<int?>())
                             .Returns((HasDueDatePresentationColumn: false, HasAllDatePresentationColumn: false));
                SearchService.GetImportanceLevels();

                Subject = new CaseSearchViewController(db, SecurityContext, PreferredCultureResolver, UserFilteredTypes, CaseAttributes, InprotechVersionChecker, CaseSavedSearch, SiteControlReader, SearchService, TaskSecurityProvider);
            }

            public ISecurityContext SecurityContext { get; set; }
            public ICaseSearchService SearchService { get; }
            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public IInprotechVersionChecker InprotechVersionChecker { get; set; }
            public IUserFilteredTypes UserFilteredTypes { get; set; }
            public ICaseAttributes CaseAttributes { get; set; }
            public CaseSearchViewController Subject { get; }
            public ICaseSavedSearch CaseSavedSearch { get; set; }
            public ISiteControlReader SiteControlReader { get; set; }
            public IImportanceLevelResolver ImportanceLevelResolver { get; set; }
            public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        }
    }
}