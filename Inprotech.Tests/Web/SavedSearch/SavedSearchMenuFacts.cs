using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.SavedSearch;
using Inprotech.Web.Search;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.SavedSearch
{
    public class SavedSearchMenuFacts
    {
        public class SavedSearchMenuFixture : IFixture<SavedSearchMenu>
        {
            public SavedSearchMenuFixture()
            {
                SavedQueries = Substitute.For<ISavedQueries>();

                Subject = new SavedSearchMenu(SavedQueries);
            }

            public ISavedQueries SavedQueries { get; set; }
            
            public SavedSearchMenu Subject { get; }
        }

        public class BuildMethod
        {
            public List<SavedQueryData> GetData()
            {
                return new List<SavedQueryData>
                {
                    new SavedQueryData
                    {
                        Key = 1,
                        Name = "US Trademark",
                        Description = "US Trademark",
                        IsPublic = true,
                        IsMaintainable = true,
                        IsRunable = true,
                        IsReportOnly = false
                    },
                    new SavedQueryData
                    {
                        Key = 2,
                        Name = "AU Trademark",
                        Description = "Us Trademark",
                        IsPublic = true,
                        IsMaintainable = true,
                        IsRunable = true,
                        IsReportOnly = false
                    },
                    new SavedQueryData
                    {
                        Key = 3,
                        Name = "India Trademark Very Long Text",
                        IsPublic = false,
                        IsMaintainable = true,
                        IsRunable = true,
                        IsReportOnly = false
                    },
                    new SavedQueryData
                    {
                        Key = 4,
                        Name = "US Patent",
                        Description = "US Patent",
                        IsPublic = true,
                        IsMaintainable = true,
                        IsRunable = true,
                        IsReportOnly = false,
                        GroupKey = 1,
                        GroupName = "Patents"
                    },
                    new SavedQueryData
                    {
                        Key = 5,
                        Name = "UK Patent",
                        Description = "UK Patent Description",
                        IsPublic = false,
                        IsMaintainable = true,
                        IsRunable = true,
                        IsReportOnly = false,
                        GroupKey = 1,
                        GroupName = "Patents"
                    },
                    new SavedQueryData
                    {
                        Key = 6,
                        Name = "Class 1",
                        Description = "Class 1",
                        IsPublic = true,
                        IsMaintainable = true,
                        IsRunable = true,
                        IsReportOnly = false,
                        GroupKey = 2,
                        GroupName = "Classes"
                    },
                    new SavedQueryData
                    {
                        Key = 7,
                        Name = "Class 2",
                        Description = "Class 2",
                        IsPublic = false,
                        IsMaintainable = true,
                        IsRunable = true,
                        IsReportOnly = false,
                        GroupKey = 2,
                        GroupName = "Classes"
                    },
                    new SavedQueryData
                    {
                        Key = 8,
                        Name = "CPA Report",
                        Description = "CPA Report",
                        IsPublic = false,
                        IsMaintainable = true,
                        IsRunable = true,
                        IsReportOnly = true
                    }
                };
            }

            [Fact]
            public void ReturnsMenuItemsArray()
            {
                var data = GetData();
                var search = string.Empty;

                var f = new SavedSearchMenuFixture();
                f.SavedQueries.Get(search, QueryContext.CaseSearch, QueryType.All).Returns(data);

                var result = f.Subject.Build(QueryContext.CaseSearch, search).ToList();
                Assert.Equal(5 , result.Count);

                var firstMenu = result.First();
                Assert.Equal("3", firstMenu.Key);
                Assert.Equal("India Trademark Very Long Text", firstMenu.Text);
                Assert.Equal("India Trademark Very Long Text", firstMenu.Description);
                Assert.Equal("cpa-icon-lg", firstMenu.Icon);
                Assert.Equal("#/search-result?queryContext=2&queryKey=3", firstMenu.Url);

                var groupMenuLast = result.Last();
                Assert.Equal("1^Group", groupMenuLast.Key);
                Assert.Equal("Patents", groupMenuLast.Text);
                Assert.Equal(string.Empty, groupMenuLast.Description);
                Assert.Null(groupMenuLast.Icon);
                Assert.Null(groupMenuLast.Url);

                Assert.NotNull(groupMenuLast.Items);
                Assert.Equal("5", groupMenuLast.Items.First().Key);
                Assert.Equal("UK Patent : UK Patent Description", groupMenuLast.Items.First().Description);
            }
        }
    }
}
