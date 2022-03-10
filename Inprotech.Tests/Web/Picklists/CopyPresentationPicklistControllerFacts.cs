using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Web.Picklists;
using Inprotech.Web.Search;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class CopyPresentationPicklistControllerFacts
    {
        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnsCopySavedPresentations()
            {
                var f = new CopyPresentationPicklistControllerFixture();

                var r = f.Subject.Get(null, null, 52);
                SavedPresentation[] data = r.Data;

                Assert.Equal(4, data.Length);
                Assert.Contains("Group Name A", data.Select(x => x.GroupName));
                Assert.Contains("1", data.Select(x => x.Key));
                Assert.Contains("Group A", data.Select(x => x.Value));
            }

            [Fact]
            public void ReturnsCopySavedPresentationsByGroupName()
            {
                var f = new CopyPresentationPicklistControllerFixture();

                var r = f.Subject.Get(null, "Group Name C", 52);
                SavedPresentation[] data = r.Data;

                Assert.Equal(1, data.Length);
                Assert.Contains("Group Name C", data.Select(x => x.GroupName));
                Assert.Contains("3", data.Select(x => x.Key));
                Assert.Contains("Group C", data.Select(x => x.Value));
            }

            [Fact]
            public void ReturnsCopySavedPresentationsByValue()
            {
                var f = new CopyPresentationPicklistControllerFixture();

                var r = f.Subject.Get(null, "Group A", 52);
                SavedPresentation[] data = r.Data;

                Assert.Equal(1, data.Length);
                Assert.Contains("Group Name A", data.Select(x => x.GroupName));
                Assert.Contains("1", data.Select(x => x.Key));
            }

            [Fact]
            public void ReturnsArgumentException()
            {
                var f = new CopyPresentationPicklistControllerFixture();
                Assert.Throws<ArgumentNullException>(() => { f.Subject.Get(); });
            }

        }

    }

    public class CopyPresentationPicklistControllerFixture : IFixture<CopyPresentationPicklistController>
    {
        public CopyPresentationPicklistControllerFixture()
        {
            SavedQueries = Substitute.For<ISavedQueries>();
            SavedQueries.GetSavedPresentationQueries(Arg.Any<int>()).Returns(ResultData());
            Subject = new CopyPresentationPicklistController(SavedQueries);

        }

        ISavedQueries SavedQueries { get; set; }

        public CopyPresentationPicklistController Subject { get; }

        static IEnumerable<dynamic> ResultData()
        {
            return new List<SavedPresentationFact> { new SavedPresentationFact { GroupName = "Group Name A", Key = "1", Name = "Group A" }, new SavedPresentationFact { GroupName = "Group Name B", Key = "2", Name = "Group B" }, new SavedPresentationFact { GroupName = "Group Name C", Key = "3", Name = "Group C" }, new SavedPresentationFact { GroupName = "Group Name D", Key = "4", Name = "Group D" } };
        }
    }

    internal class SavedPresentationFact
    {
        public string Key { get; set; }

        public string Name { get; set; }

        public string GroupName { get; set; }

    }
}
