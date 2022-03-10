using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Queries
{
    public class PresentationColumnsResolverFacts
    {
        public class PresentationColumnsResolverFixture : IFixture<PresentationColumnsResolver>
        {
            public PresentationColumnsResolverFixture(InMemoryDbContext db)
            {
                DbContext = db;
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.Returns(new User("xyz", false));
                SubjectSecurity = Substitute.For<ISubjectSecurityProvider>();
                Subject = new PresentationColumnsResolver(DbContext, PreferredCultureResolver, SecurityContext, SubjectSecurity);
            }

            public InMemoryDbContext DbContext { get; set; }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }

            public ISecurityContext SecurityContext { get; set; }

            public ISubjectSecurityProvider SubjectSecurity { get; }

            public PresentationColumnsResolver Subject { get; }
        }

        public class ResolveMethod : FactBase
        {
            const int DataItemId = 2;
            const int ColumnId = -77;
            const QueryContext ContextId = QueryContext.CaseSearch;
            const int PresentationId = 35;
            const int QueryKey = 45;
            const int TopicId = 1;

            public void SetupData(QueryContext contextId, bool? isSavedQuery = false, int? userIdentityId = null, QualifierType? qualifierType = null, string qualifier = null)
            {
                if (isSavedQuery.HasValue && isSavedQuery.Value)
                {
                    new Query {ContextId = (int) contextId, Id = QueryKey, PresentationId = PresentationId}.In(Db);
                }

                new QueryContextColumn {ColumnId = ColumnId, ContextId = (int) ContextId, GroupId = Fixture.Integer()}.In(Db);
                new QueryDataItem {DataItemId = DataItemId, QualifierType = (short?) qualifierType}.In(Db);
                new QueryColumn {ColumnId = ColumnId, DataItemId = DataItemId, Qualifier = qualifier}.In(Db);
                new QueryContent {ColumnId = ColumnId, ContentId = Fixture.Integer(), ContextId = (int) contextId, PresentationId = PresentationId}.In(Db);
                new QueryPresentation {ContextId = (int) contextId, Id = PresentationId, IsDefault = true, PresentationType = null, IdentityId = userIdentityId}.In(Db);
                new TopicDataItems {DataItemId = DataItemId, TopicId =TopicId}.In(Db);
            }

            [Theory]
            [InlineData(true, false)]
            [InlineData(false, false)]
            [InlineData(false, true)]
            public void ShouldReturnPresentationColumnForGivenContext(bool defaultPresentation, bool isSavedQuery)
            {
                var f = new PresentationColumnsResolverFixture(Db);

                SetupData(ContextId, isSavedQuery, defaultPresentation ? (int?) null : f.SecurityContext.User.Id);
                f.SubjectSecurity.AvailableSubjectsFromDb().Returns(new List<SubjectAccess>
                {
                    new SubjectAccess {TopicId = 1,CanSelect = false}
                }.AsQueryable());

                var r = f.Subject.Resolve(isSavedQuery ? QueryKey : (int?) null, ContextId).ToArray();

                Assert.NotEmpty(r);
                Assert.Equal(r.Length, 1);
                Assert.Equal(r[0].ColumnKey, ColumnId);
                Assert.Equal(r[0].DataItemKey, DataItemId);
            }

            [Theory]
            [InlineData(QualifierType.UserTextTypes)]
            [InlineData(QualifierType.UserAliasTypes)]
            [InlineData(QualifierType.UserNameTypes)]
            [InlineData(QualifierType.UserNumberTypes)]
            public void ShouldNotReturnPresentationIfQualifierIsNotPassed(QualifierType qualifierType)
            {
                var f = new PresentationColumnsResolverFixture(Db);

                SetupData(ContextId, false, null, qualifierType, "abc");
                var r = f.Subject.Resolve(10, ContextId).ToArray();

                Assert.Empty(r);
            }

            [Theory]
            [InlineData(QualifierType.UserTextTypes, KnownTextTypes.GoodsServices)]
            [InlineData(QualifierType.UserNumberTypes, KnownNumberTypes.Application)]
            [InlineData(QualifierType.UserNameTypes, KnownNameTypes.Agent)]
            [InlineData(QualifierType.UserAliasTypes, KnownAliasTypes.FileAgentId)]
            public void ShouldReturnPresentationIfQualifierIsValid(QualifierType qualifierType, string qualifier)
            {
                var f = new PresentationColumnsResolverFixture(Db);

                new FilteredUserTextTypeBuilder {TextTypeId = KnownTextTypes.GoodsServices}.Build().In(Db);
                new FilteredUserNumberTypes {Description = Fixture.String(), NumberType = KnownNumberTypes.Application}.In(Db);
                new FilteredUserNameTypes {Description = Fixture.String(), NameType = KnownNameTypes.Agent}.In(Db);
                new FilteredUserAliasTypes {AliasDescription = Fixture.String(), AliasType = KnownAliasTypes.FileAgentId}.In(Db);

                SetupData(ContextId, false, null, qualifierType, qualifier);
                f.SubjectSecurity.AvailableSubjectsFromDb().Returns(new List<SubjectAccess>
                {
                    new SubjectAccess {TopicId = 1,CanSelect = false}
                }.AsQueryable());
                var r = f.Subject.Resolve(null, ContextId).ToArray();

                Assert.NotEmpty(r);
            }

            [Fact]
            public void ShouldNotReturnPresentationColumnForIfContextIsWrong()
            {
                var f = new PresentationColumnsResolverFixture(Db);

                SetupData(ContextId);

                var r = f.Subject.Resolve(null, QueryContext.CaseSearchExternal).ToArray();

                Assert.Empty(r);
            }

            [Fact]
            public void ShouldReturnPresentationColumnForSubjectSecurityEnabled()
            {
                var f = new PresentationColumnsResolverFixture(Db);

                SetupData(ContextId);
                f.SubjectSecurity.AvailableSubjectsFromDb().Returns(new List<SubjectAccess>
                {
                    new SubjectAccess {TopicId = 1,CanSelect = true}
                }.AsQueryable());

                var r = f.Subject.Resolve( null, ContextId).ToArray();

                Assert.NotEmpty(r);
                Assert.Equal(r.Length, 1);
                Assert.Equal(r[0].ColumnKey, ColumnId);
                Assert.Equal(r[0].DataItemKey, DataItemId);
            }
        }

        public class AvailableColumnGroupsMethod : FactBase
        {
            public void SetupData()
            {
                var group1 = new QueryColumnGroup {GroupName = Fixture.String("F"), Id = Fixture.Integer(), ContextId = 2}.In(Db);
                var group2 = new QueryColumnGroup {GroupName = Fixture.String("B"), Id = Fixture.Integer(), ContextId = 2}.In(Db);
                new QueryColumnGroup {GroupName = Fixture.String("A"), Id = Fixture.Integer(), ContextId = 3}.In(Db);
                var group3 = new QueryColumnGroup {GroupName = Fixture.String("D"), Id = Fixture.Integer(), ContextId = 2}.In(Db);

                new QueryContextColumn {ColumnId = 1, ContextId = 2, Group = group1}.In(Db);
                new QueryContextColumn {ColumnId = 2, ContextId = 2, Group = group2}.In(Db);
                new QueryContextColumn {ColumnId = 3, ContextId = 2, Group = group3}.In(Db);
            }

            [Fact]
            public void ShouldNotReturnColumnGroupIfThereAreNoAssociatedColumns()
            {
                var f = new PresentationColumnsResolverFixture(Db);

                new QueryColumnGroup {GroupName = Fixture.String("A"), Id = Fixture.Integer(), ContextId = 2}.In(Db);

                var r = f.Subject.AvailableColumnGroups(QueryContext.CaseSearch).ToArray();

                Assert.Equal(r.Length, 0);
            }

            [Fact]
            public void ShouldReturnValidColumnGroupInAscendingOrder()
            {
                var f = new PresentationColumnsResolverFixture(Db);

                SetupData();

                var r = f.Subject.AvailableColumnGroups(QueryContext.CaseSearch).ToArray();

                Assert.Equal(r.Length, 3);
                Assert.True(r.First().GroupName.StartsWith("B"));
                Assert.True(r.Last().GroupName.StartsWith("F"));
            }
        }

        public class AvailableColumnMethod : FactBase
        {
            public void SetupData()
            {
                var columnId = new[] {1, 2, 3};
                var contextId = 2;
                var dataItemId = new[] {1, 2, 3};
                var topicId = new[] {1, 2};

                var group = new QueryColumnGroup {Id = Fixture.Integer(), GroupName = Fixture.String("G")}.In(Db);

                new QueryContextColumn {ColumnId = columnId[0], ContextId = contextId, Group = group, IsMandatory = true, IsSortOnly = true}.In(Db);
                new QueryContextColumn {ColumnId = columnId[1], ContextId = contextId, IsMandatory = true, IsSortOnly = false}.In(Db);
                new QueryContextColumn {ColumnId = columnId[2], ContextId = 1, GroupId = Fixture.Integer()}.In(Db);

                new QueryDataItem {DataItemId = dataItemId[0], QualifierType = null, DataFormatId = (int) KnownColumnFormat.Text}.In(Db);
                new QueryDataItem {DataItemId = dataItemId[1], QualifierType = null, DataFormatId = (int) KnownColumnFormat.Integer, SortDirection = "A"}.In(Db);

                new QueryColumn {ColumnId = columnId[0], DataItemId = dataItemId[0], Qualifier = null, ColumnLabel = Fixture.String("B")}.In(Db);
                new QueryColumn {ColumnId = columnId[1], DataItemId = dataItemId[1], Qualifier = null, ColumnLabel = "A"}.In(Db);
                
                new TopicDataItems {DataItemId = dataItemId[0], TopicId = topicId[0]}.In(Db);
                new TopicDataItems {DataItemId = dataItemId[1], TopicId = topicId[1]}.In(Db);

                          }

            [Fact]
            public void ShouldReturnAvailableColumnsInAscendingOrder()
            {
                var f = new PresentationColumnsResolverFixture(Db);

                SetupData();

                f.SubjectSecurity.AvailableSubjectsFromDb().Returns(new List<SubjectAccess>
                {
                    new SubjectAccess {TopicId = 1, CanSelect = false},
                    new SubjectAccess {TopicId = 2, CanSelect = false}
                }.AsQueryable());

                var r = f.Subject.AvailableColumns(QueryContext.CaseSearch).ToArray();

                var first = r.First();
                var last = r.Last();

                Assert.Equal(r.Length, 2);

                Assert.True(first.ColumnLabel.StartsWith("A"));
                Assert.Null(first.GroupName);
                Assert.True(first.ColumnKey.Equals(2));
                Assert.False(first.IsDisplayMandatory);
                Assert.True(first.IsDisplayable);
                Assert.True(first.IsGroupable);
                Assert.Equal(first.SortDirection, "A");

                Assert.True(last.ColumnLabel.StartsWith("B"));
                Assert.True(last.GroupName.StartsWith("G"));
                Assert.True(last.ColumnKey.Equals(1));
                Assert.True(last.IsDisplayMandatory);
                Assert.False(last.IsDisplayable);
                Assert.False(last.IsGroupable);
                Assert.Null(last.SortDirection);
            }

            [Fact]
            public void ShouldReturnAvailableColumnsForSubjectSecurityEnabled()
            {
                var f = new PresentationColumnsResolverFixture(Db);

                SetupData();

                f.SubjectSecurity.AvailableSubjectsFromDb().Returns(new List<SubjectAccess>
                {
                    new SubjectAccess {TopicId = 1, CanSelect = true},
                    new SubjectAccess {TopicId = 2, CanSelect = true}
                }.AsQueryable());

                var r = f.Subject.AvailableColumns(QueryContext.CaseSearch).ToArray();

                Assert.NotEmpty(r);
                Assert.Equal(r.Length, 2);
                Assert.Equal(r[0].ColumnKey, 2);
                Assert.True(r[1].ColumnLabel.StartsWith("B"));
            }
        }
    }
}