using System.Collections.Generic;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Search;
using Xunit;

namespace Inprotech.Tests.Web.Search
{
    public class SelectedColumnsExtensionFacts
    {
        readonly string _expectedResult = @"<SelectedColumns>
  <Column>
    <ColumnKey>1</ColumnKey>
    <DisplaySequence>1</DisplaySequence>
    <SortDirection>A</SortDirection>
    <SortOrder>1</SortOrder>
    <GroupBySortDirection />
    <GroupBySortOrder />
    <IsFreezeColumnIndex>true</IsFreezeColumnIndex>
  </Column>
  <Column>
    <ColumnKey>2</ColumnKey>
    <DisplaySequence>2</DisplaySequence>
    <SortDirection />
    <SortOrder />
    <GroupBySortDirection />
    <GroupBySortOrder />
    <IsFreezeColumnIndex>false</IsFreezeColumnIndex>
  </Column>
</SelectedColumns>";

        [Fact]
        public void AddDueDateFilterIfNotExist()
        {
            var selectedColumns = new List<SelectedColumn>
            {
                new SelectedColumn {ColumnKey = 1, DisplaySequence = 1, IsFreezeColumnIndex = true, SortOrder = 1, SortDirection = "A"},
                new SelectedColumn {ColumnKey = 2, DisplaySequence = 2}
            };
            var result = selectedColumns.ToXml().Replace("\r", string.Empty);
            Assert.Equal(_expectedResult.Replace("\r", string.Empty), result);
        }
    }
}