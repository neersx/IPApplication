using System.Linq;
using Inprotech.Tests.Web.Search.CaseSupportData;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;
using TextType = Inprotech.Web.Picklists.TextType;

namespace Inprotech.Tests.Web.Picklists
{
    public class TextTypesPicklistControllerFacts : FixtureBase
    {
        TextTypesPicklistController CreateSubject(params TextTypeListItem[] textTypes)
        {
            WithUser(new User());
            WithCulture(string.Empty);
            WithSqlResults(textTypes);

            return new TextTypesPicklistController(DbContext, SecurityContext, PreferredCultureResolver);
        }

        [Fact]
        public void ReturnsTextTypes()
        {
            var subject = CreateSubject(new TextTypeListItem
            {
                TextTypeKey = "a",
                TextTypeDescription = "a1"
            },
                                        new TextTypeListItem
                                        {
                                            TextTypeKey = "b",
                                            TextTypeDescription = "b1"
                                        });

            var r = subject.Get().Data.Cast<TextType>().ToArray();

            Assert.Equal(2, r.Length);

            Assert.Equal("a", r[0].Key);
            Assert.Equal("a1", r[0].Value);

            Assert.Equal("b", r[1].Key);
            Assert.Equal("b1", r[1].Value);
        }

        [Fact]
        public void ReturnsTextTypesFiltered()
        {
            var subject = CreateSubject(new TextTypeListItem
            {
                TextTypeKey = "ahappy",
                TextTypeDescription = "a123"
            },
                                        new TextTypeListItem
                                        {
                                            TextTypeKey = "s2ss",
                                            TextTypeDescription = "c13"
                                        },
                                        new TextTypeListItem
                                        {
                                            TextTypeKey = "bsnoopy",
                                            TextTypeDescription = "b123"
                                        });

            var r = subject.Get(search: "2").Data.Cast<TextType>().ToArray();

            Assert.Equal(2, r.Length);

            Assert.Equal("ahappy", r[0].Key);
            Assert.Equal("bsnoopy", r[1].Key);
        }

        [Fact]
        public void ReturnsTextTypesExactMatch()
        {
            var subject = CreateSubject(new TextTypeListItem
            {
                TextTypeKey = "a",
                TextTypeDescription = "a1"
            },
                                        new TextTypeListItem
                                        {
                                            TextTypeKey = "b",
                                            TextTypeDescription = "b1"
                                        });

            const string searchText = "b";
            var r = subject.Get(search: searchText).Data.Cast<TextType>().ToArray();

            Assert.Single(r);

            Assert.Equal("b", r[0].Key);
            Assert.Equal("b1", r[0].Value);
        }
    }
}