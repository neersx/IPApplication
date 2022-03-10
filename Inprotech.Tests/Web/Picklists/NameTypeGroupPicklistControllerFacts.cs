using System;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Picklists;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class NameTypeGroupPicklistControllerFacts : FactBase
    {
        public class SearchMethod : FactBase
        {
            NameTypeGroupsPicklistController CreateSubject()
            {
                var cultureResolver = Substitute.For<IPreferredCultureResolver>();
                var nameTypeGroupsPicklistMaintenance = Substitute.For<INameTypeGroupsPicklistMaintenance>();
                return new NameTypeGroupsPicklistController(Db, cultureResolver, nameTypeGroupsPicklistMaintenance);
            }

            void BuildNameGroup(string group, params string[] nameTypes)
            {
                var ng = new NameGroupBuilder {GroupName = group}.Build().In(Db);

                foreach (var nt in nameTypes)
                {
                    ng.Members.Add(new NameGroupMemberBuilder
                    {
                        NameGroup = ng,
                        NameType = new NameTypeBuilder
                        {
                            Name = nt
                        }.Build().In(Db)
                    }.Build().In(Db));
                }
            }

            [Fact]
            public void ReturnsExactMatchEntry()
            {
                BuildNameGroup("cde");
                BuildNameGroup("abc");
                BuildNameGroup("dfg");

                var subject = CreateSubject();

                var r = subject.Get(search: "abc")
                               .Data.Cast<NameTypeGroup>()
                               .ToArray();

                Assert.Equal("abc", r.Single().Value);
            }

            [Fact]
            public void ReturnsNameTypeGroupsContainingSearchString()
            {
                BuildNameGroup("cde");
                BuildNameGroup("abc");
                BuildNameGroup("dfg");

                var subject = CreateSubject();

                var r = subject.Get(search: "d")
                               .Data.Cast<NameTypeGroup>()
                               .ToArray();

                Assert.Equal(new[] {"dfg", "cde"}, r.Select(_ => _.Value));
            }

            [Fact]
            public void ReturnsNameTypeGroupsOrderedAlphabeticallyByDefault()
            {
                BuildNameGroup("cde");
                BuildNameGroup("abc");

                var subject = CreateSubject();

                var r = subject.Get().Ids;

                var s = subject.Get().Data.Cast<NameTypeGroup>()
                               .ToArray();

                Assert.NotNull(r);
                Assert.Equal(s.Length, r.AsDataServiceValue()["Value"].Count());
                Assert.Equal(new[] {"abc", "cde"}, s.Select(_ => _.Value));
            }

            [Fact]
            public void ReturnsNameTypeGroupsWithMembers()
            {
                BuildNameGroup("the abc group", "a", "b", "c");
                BuildNameGroup("the de group", "d", "e");

                var subject = CreateSubject();

                var r = subject.Get().Data.Cast<NameTypeGroup>()
                               .ToArray();

                Assert.Equal(2, r.Length);
                Assert.Contains(r, _ => _.NameTypes == "a, b, c");
                Assert.Contains(r, _ => _.NameTypes == "d, e");
            }
        }

        public class AddMethod : FactBase
        {
            NameTypeGroupsPicklistController CreateSubject()
            {
                var cultureResolver = Substitute.For<IPreferredCultureResolver>();
                var nameTypeGroupsPicklistMaintenance = Substitute.For<INameTypeGroupsPicklistMaintenance>();
                return new NameTypeGroupsPicklistController(Db, cultureResolver, nameTypeGroupsPicklistMaintenance);
            }

            [Fact]
            public void ReturnExceptionWhenNullIsPassed()
            {
                var s = CreateSubject();

                var exception =
                    Record.Exception(() => s.Add(null));

                Assert.IsType<ArgumentNullException>(exception);
            }
        }

        public class UpdateMethod : FactBase
        {
            NameTypeGroupsPicklistController CreateSubject()
            {
                var cultureResolver = Substitute.For<IPreferredCultureResolver>();
                var nameTypeGroupsPicklistMaintenance = Substitute.For<INameTypeGroupsPicklistMaintenance>();
                return new NameTypeGroupsPicklistController(Db, cultureResolver, nameTypeGroupsPicklistMaintenance);
            }

            [Fact]
            public void ReturnExceptionWhenNullIsPassed()
            {
                var s = CreateSubject();
                var model = new NameTypeGroup();
                var exception =
                    Record.Exception(() => s.Update(model.Key.ToString(), null));

                Assert.IsType<ArgumentNullException>(exception);
            }
        }

        public class DeleteMethod : FactBase
        {
            NameTypeGroupsPicklistController CreateSubject()
            {
                var cultureResolver = Substitute.For<IPreferredCultureResolver>();
                var nameTypeGroupsPicklistMaintenance = Substitute.For<INameTypeGroupsPicklistMaintenance>();
                return new NameTypeGroupsPicklistController(Db, cultureResolver, nameTypeGroupsPicklistMaintenance);
            }

            [Fact]
            public void CallsDelete()
            {
                var s = CreateSubject();
                var r = new object();

                s.Delete(1)
                 .ReturnsForAnyArgs(r);

                Assert.Equal(r, s.Delete(1));
            }
        }
    }
}